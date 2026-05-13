"""Тесты ChatService без реальных HTTP и RAG."""

import pytest
from unittest.mock import AsyncMock, MagicMock

from halal_rag.api.dto import ChatRequest
from halal_rag.api.services import ChatService


@pytest.fixture
def mock_rag():
    rag = MagicMock()
    rag.search = MagicMock(
        return_value=[{"sura": 2, "verse": "173", "text": "Запрет свинины", "score": 0.9}]
    )
    return rag


@pytest.fixture
def service(mock_rag):
    s = ChatService(rag=mock_rag, llm_client=None)
    s.openrouter_client.generate = AsyncMock(return_value="Краткий ответ с ссылкой на аят.")
    return s


def test_extract_user_message_last_user_wins(service):
    messages = [
        {"role": "system", "content": "sys"},
        {"role": "user", "content": "первый"},
        {"role": "assistant", "content": "ok"},
        {"role": "user", "content": "  второй  "},
    ]
    assert service.extract_user_message(messages) == "второй"


def test_extract_user_message_empty(service):
    assert service.extract_user_message([{"role": "assistant", "content": "x"}]) == ""


def test_search_sources_empty_query(service, mock_rag):
    assert service.search_sources("") == []
    mock_rag.search.assert_not_called()


def test_format_sources_empty(service):
    assert service.format_sources([]) == "No sources found"


def test_format_sources_joins(service):
    src = [{"sura": 1, "verse": "1", "text": "Аят"}]
    out = service.format_sources(src)
    assert "Сура 1:1" in out
    assert "Аят" in out


def test_handle_error_none_message(service):
    msg = service.handle_error(None)
    assert "недоступна" in msg.lower() or "проверьте" in msg.lower()


def test_handle_error_429(service):
    msg = service.handle_error("429 Too Many Requests")
    assert "429" in msg


def test_handle_error_401(service):
    msg = service.handle_error("401 Unauthorized")
    assert "ключ" in msg.lower() or "аутентификац" in msg.lower()


def test_handle_error_generic(service):
    msg = service.handle_error("something weird")
    assert "something weird" in msg


@pytest.mark.asyncio
async def test_generate_response_no_api_key(service):
    reply, used, err = await service.generate_response("q", "src", api_key=None, model="m", max_tokens=10)
    assert reply == ""
    assert used is False
    assert err == "API key is required"


@pytest.mark.asyncio
async def test_generate_response_openrouter_failure(service):
    service.openrouter_client.generate = AsyncMock(side_effect=RuntimeError("network down"))
    reply, used, err = await service.generate_response(
        "q", "src", api_key="k", model="m", max_tokens=10
    )
    assert reply == ""
    assert used is False
    assert "network down" in err


@pytest.mark.asyncio
async def test_process_chat_missing_user_message(service):
    req = ChatRequest(messages=[{"role": "assistant", "content": "x"}], api_key="k")
    resp = await service.process_chat(req)
    assert "No user message" in resp.reply


@pytest.mark.asyncio
async def test_process_chat_success_with_rag(service, mock_rag):
    req = ChatRequest(
        messages=[{"role": "user", "content": "Свинина дозволена?"}],
        api_key="sk-test",
        use_rag=True,
    )
    resp = await service.process_chat(req)
    mock_rag.search.assert_called()
    assert resp.used_remote is True
    assert "ответ" in resp.reply.lower() or len(resp.reply) > 0


@pytest.mark.asyncio
async def test_process_chat_rag_disabled_skips_search(service, mock_rag):
    req = ChatRequest(
        messages=[{"role": "user", "content": "Привет"}],
        api_key="k",
        use_rag=False,
    )
    await service.process_chat(req)
    mock_rag.search.assert_not_called()


@pytest.mark.asyncio
async def test_process_chat_empty_llm_reply_triggers_handle_error(service, mock_rag):
    service.openrouter_client.generate = AsyncMock(return_value="")
    req = ChatRequest(
        messages=[{"role": "user", "content": "Вопрос"}],
        api_key="k",
        use_rag=False,
    )
    resp = await service.process_chat(req)
    assert resp.reply
    assert "недоступна" in resp.reply.lower() or "OpenRouter" in resp.reply or "проверьте" in resp.reply.lower()


def test_build_prompt_with_and_without_sources(service):
    sys_p, usr_p = service.build_prompt("Вопрос", "  \nисточник\n  ")
    assert "HalalAI" in sys_p
    assert "Вопрос" in usr_p
    assert "источник" in usr_p

    _, usr2 = service.build_prompt("Вопрос", "   ")
    assert "Вопрос" in usr2
    assert "Соответствующие аяты" not in usr2
