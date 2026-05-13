"""Тесты OpenRouterClient с подменой httpx."""

import pytest
from unittest.mock import AsyncMock, MagicMock

import httpx

from halal_rag.llm.open_router import OpenRouterClient


@pytest.fixture
def client():
    return OpenRouterClient(model="test/model")


@pytest.mark.asyncio
async def test_generate_success(client):
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {
        "choices": [{"message": {"content": "Итоговый текст"}}],
        "usage": {"total_tokens": 42},
    }
    client.client.post = AsyncMock(return_value=mock_resp)
    out = await client.generate("вопрос", "источники", api_key="secret", model="x/y")

    assert out == "Итоговый текст"
    client.client.post.assert_awaited_once()
    call_kw = client.client.post.await_args
    assert call_kw[0][0] == "/chat/completions"
    headers = call_kw[1]["headers"]
    assert headers["Authorization"] == "Bearer secret"


@pytest.mark.asyncio
async def test_generate_uses_default_system_prompt(client):
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {
        "choices": [{"message": {"content": "ok"}}],
        "usage": {"total_tokens": 1},
    }
    client.client.post = AsyncMock(return_value=mock_resp)
    await client.generate("q", "", api_key="k", system_prompt=None)

    body = client.client.post.await_args[1]["json"]
    assert body["messages"][0]["role"] == "system"
    assert "HalalAI" in body["messages"][0]["content"]


@pytest.mark.asyncio
async def test_generate_http_error_propagates(client):
    client.client.post = AsyncMock(side_effect=httpx.HTTPError("boom"))
    with pytest.raises(httpx.HTTPError):
        await client.generate("q", "s", api_key="k")


@pytest.mark.asyncio
async def test_generate_bad_json_raises_valueerror(client):
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {"choices": []}
    client.client.post = AsyncMock(return_value=mock_resp)
    with pytest.raises(ValueError, match="Invalid OpenRouter"):
        await client.generate("q", "s", api_key="k")


@pytest.mark.asyncio
async def test_generate_success_without_usage_field(client):
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {"choices": [{"message": {"content": "ok"}}]}
    client.client.post = AsyncMock(return_value=mock_resp)
    out = await client.generate("q", "", api_key="k")
    assert out == "ok"


@pytest.mark.asyncio
async def test_close_swallows_errors(client):
    client.client.aclose = AsyncMock(side_effect=RuntimeError("x"))
    await client.close()
