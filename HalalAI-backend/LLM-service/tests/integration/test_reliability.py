"""4.4.4 Проверка надёжности LLM-сервиса.

Проверяет корректную деградацию, восстановление после сбоев и устойчивость
к некорректным входным данным.
"""
from unittest.mock import AsyncMock, MagicMock

import pytest


# ── Health-эндпоинт ───────────────────────────────────────────────────────────

def test_health_always_returns_ok(client):
    """Health-эндпоинт доступен и возвращает статус ok."""
    r = client.get("/llm/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"


def test_health_shows_rag_ready_when_initialized(client):
    """Health показывает rag_ready=ready когда RAG инициализирован."""
    r = client.get("/llm/health")
    assert r.status_code == 200
    assert r.json()["rag_ready"] == "ready"


def test_health_remains_available_after_multiple_chat_requests(client):
    """Health работает до и после серии chat-запросов."""
    assert client.get("/llm/health").status_code == 200

    for i in range(5):
        client.post(
            "/llm/chat",
            json={
                "messages": [{"role": "user", "content": f"Вопрос {i}"}],
                "api_key": "k",
            },
        )

    assert client.get("/llm/health").status_code == 200


# ── Корректная деградация при сбоях ──────────────────────────────────────────

def test_chat_service_not_initialized_returns_503(client, monkeypatch):
    """Если ChatService не инициализирован — 503, не 500 и не краш."""
    monkeypatch.setattr("halal_rag.api.dependencies.get_chat_service", lambda: None)

    r = client.post(
        "/llm/chat",
        json={"messages": [{"role": "user", "content": "Q"}], "api_key": "k"},
    )
    assert r.status_code == 503
    assert "not initialized" in r.json().get("detail", "").lower()


def test_chat_llm_error_returns_reply_not_500(client, monkeypatch):
    """При сбое OpenRouter сервис возвращает 200 с сообщением об ошибке, не 500."""
    monkeypatch.setattr(
        "halal_rag.llm.open_router.OpenRouterClient.generate",
        AsyncMock(side_effect=RuntimeError("upstream timeout")),
    )

    r = client.post(
        "/llm/chat",
        json={
            "messages": [{"role": "user", "content": "Свинина дозволена?"}],
            "api_key": "test-key",
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert "reply" in data
    assert data["reply"], "reply не должен быть пустым при ошибке LLM"


def test_empty_messages_returns_400_not_500(client):
    """Пустой список messages → 400 Bad Request, не 500."""
    r = client.post("/llm/chat", json={"messages": []})
    assert r.status_code == 400


# ── Повторяемость запросов ────────────────────────────────────────────────────

def test_sequential_chat_requests_all_succeed(client):
    """10 последовательных chat-запросов должны все вернуть 200."""
    statuses = []
    for i in range(10):
        r = client.post(
            "/llm/chat",
            json={
                "messages": [{"role": "user", "content": f"Вопрос {i}"}],
                "api_key": "test-key",
            },
        )
        statuses.append(r.status_code)

    assert all(s == 200 for s in statuses), (
        f"Некоторые запросы вернули ошибку: {statuses}"
    )


def test_service_recovers_after_llm_failure(client, monkeypatch):
    """После сбоя LLM следующий запрос (после восстановления LLM) должен успешно выполниться."""
    # Первый вызов — сбой
    monkeypatch.setattr(
        "halal_rag.llm.open_router.OpenRouterClient.generate",
        AsyncMock(side_effect=RuntimeError("временный сбой")),
    )
    r1 = client.post(
        "/llm/chat",
        json={"messages": [{"role": "user", "content": "Q"}], "api_key": "k"},
    )
    # Ожидаем либо 200 с сообщением об ошибке (если ChatService поглощает), либо 500
    assert r1.status_code in (200, 500)

    # LLM восстановился
    monkeypatch.setattr(
        "halal_rag.llm.open_router.OpenRouterClient.generate",
        AsyncMock(return_value="Ответ после восстановления"),
    )
    r2 = client.post(
        "/llm/chat",
        json={"messages": [{"role": "user", "content": "Q"}], "api_key": "k"},
    )
    assert r2.status_code == 200
    assert r2.json()["reply"]


# ── Некорректные форматы запросов не роняют систему ──────────────────────────

def test_missing_messages_field_returns_422_not_500(client):
    """Отсутствие поля messages → 422 (Pydantic validation), не 500."""
    r = client.post("/llm/chat", json={"api_key": "k"})
    assert r.status_code == 422


def test_non_json_body_returns_422_not_500(client):
    """Не-JSON тело запроса → 422, не 500."""
    r = client.post(
        "/llm/chat",
        content="plain text body",
        headers={"Content-Type": "application/json"},
    )
    assert r.status_code == 422


def test_repeated_health_checks_all_succeed(client):
    """20 подряд health-запросов — все успешны."""
    for _ in range(20):
        r = client.get("/llm/health")
        assert r.status_code == 200
        assert r.json()["status"] == "ok"
