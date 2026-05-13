"""HTTP API halal_rag с моком SimpleRAG (без загрузки эмбеддингов)."""

from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi.testclient import TestClient

import halal_rag.api.main as main_module


@pytest.fixture
def client(monkeypatch):
    mock_rag = MagicMock()
    mock_rag.search = MagicMock(return_value=[])

    monkeypatch.setattr(main_module, "SimpleRAG", lambda *a, **kw: mock_rag)
    monkeypatch.setattr(
        "halal_rag.llm.open_router.OpenRouterClient.generate",
        AsyncMock(return_value="Тестовый ответ без внешнего API."),
    )

    with TestClient(main_module.app) as c:
        yield c


def test_root(client):
    r = client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert "/llm/info" in body.get("message", "")


def test_llm_health(client):
    r = client.get("/llm/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert data["rag_ready"] == "ready"


def test_llm_info(client):
    r = client.get("/llm/info")
    assert r.status_code == 200
    assert "endpoints" in r.json()


def test_llm_chat_empty_messages(client):
    r = client.post("/llm/chat", json={"messages": []})
    assert r.status_code == 400


def test_llm_chat_missing_messages_key(client):
    r = client.post("/llm/chat", json={})
    assert r.status_code == 422


def test_llm_chat_service_not_initialized_returns_503(client, monkeypatch):
    monkeypatch.setattr("halal_rag.api.dependencies.get_chat_service", lambda: None)
    r = client.post(
        "/llm/chat",
        json={"messages": [{"role": "user", "content": "x"}], "api_key": "k"},
    )
    assert r.status_code == 503
    assert "not initialized" in r.json().get("detail", "").lower()


def test_llm_chat_happy_path(client):
    r = client.post(
        "/llm/chat",
        json={
            "messages": [{"role": "user", "content": "Короткий вопрос"}],
            "api_key": "dummy-key-for-test",
            "use_rag": True,
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert "reply" in data
