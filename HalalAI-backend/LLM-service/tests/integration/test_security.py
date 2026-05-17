"""4.4.5 Проверка безопасности LLM-сервиса.

Проверяет валидацию входных данных, устойчивость к инъекциям и корректную
обработку потенциально опасных входных данных.
"""
from unittest.mock import AsyncMock, MagicMock

import pytest


# ── Валидация обязательных полей ─────────────────────────────────────────────

def test_missing_messages_field_returns_422(client):
    """Отсутствие обязательного поля messages → 422 Unprocessable Entity."""
    r = client.post("/llm/chat", json={"api_key": "k"})
    assert r.status_code == 422


def test_empty_body_returns_422(client):
    """Пустое тело запроса → 422."""
    r = client.post("/llm/chat", json={})
    assert r.status_code == 422


def test_empty_messages_list_returns_400(client):
    """Пустой список messages → 400 Bad Request (бизнес-правило)."""
    r = client.post("/llm/chat", json={"messages": []})
    assert r.status_code == 400


def test_null_messages_returns_422(client):
    """Null в поле messages → 422 от Pydantic."""
    r = client.post("/llm/chat", json={"messages": None})
    assert r.status_code == 422


# ── Инъекции в контент сообщений ──────────────────────────────────────────────

def test_sql_injection_in_message_content_handled_safely(client):
    """SQL-инъекция в content не должна вызывать 500."""
    r = client.post(
        "/llm/chat",
        json={
            "messages": [{"role": "user", "content": "'; DROP TABLE users; --"}],
            "api_key": "test-key",
        },
    )
    assert r.status_code == 200, f"SQL-инъекция вызвала ошибку: {r.status_code}"
    assert "reply" in r.json()


def test_xss_in_message_content_handled_safely(client):
    """XSS-попытка в content не должна вызывать ошибку сервера."""
    r = client.post(
        "/llm/chat",
        json={
            "messages": [
                {"role": "user", "content": "<script>alert('xss')</script>"}
            ],
            "api_key": "test-key",
        },
    )
    assert r.status_code == 200
    assert "reply" in r.json()


def test_shell_injection_in_message_content_handled_safely(client):
    """Shell-инъекция в content не должна вызывать 500."""
    r = client.post(
        "/llm/chat",
        json={
            "messages": [{"role": "user", "content": "$(rm -rf /) && echo pwned"}],
            "api_key": "test-key",
        },
    )
    assert r.status_code == 200
    assert "reply" in r.json()


def test_sql_injection_in_api_key_does_not_cause_server_error(client):
    """SQL-инъекция в api_key не должна вызывать 500."""
    r = client.post(
        "/llm/chat",
        json={
            "messages": [{"role": "user", "content": "Вопрос"}],
            "api_key": "'; DROP TABLE users; --",
        },
    )
    assert r.status_code != 500, (
        f"SQL-инъекция в api_key вызвала внутреннюю ошибку сервера"
    )


# ── Размер данных ─────────────────────────────────────────────────────────────

def test_very_long_message_content_handled(client):
    """Сообщение длиной 100 000 символов не должно вызывать 500."""
    large_content = "Я хочу знать о халяле. " * 5_000  # ~100K символов
    r = client.post(
        "/llm/chat",
        json={
            "messages": [{"role": "user", "content": large_content}],
            "api_key": "test-key",
        },
    )
    assert r.status_code in (200, 400, 413, 422), (
        f"Большое сообщение вызвало неожиданный статус: {r.status_code}"
    )
    assert r.status_code != 500, "Большое сообщение вызвало внутреннюю ошибку"


def test_many_messages_in_list_handled(client):
    """100 сообщений в списке не должны вызывать 500."""
    messages = [
        {"role": "user" if i % 2 == 0 else "assistant", "content": f"Сообщение {i}"}
        for i in range(100)
    ]
    r = client.post(
        "/llm/chat",
        json={"messages": messages, "api_key": "test-key"},
    )
    assert r.status_code in (200, 400, 422), (
        f"Много сообщений вызвало неожиданный статус: {r.status_code}"
    )
    assert r.status_code != 500, "Много сообщений вызвало внутреннюю ошибку"


# ── Структура сообщений ───────────────────────────────────────────────────────

def test_message_with_null_content_handled(client):
    """Null в поле content сообщения → 422 от Pydantic или 200, не 500."""
    r = client.post(
        "/llm/chat",
        json={"messages": [{"role": "user", "content": None}], "api_key": "k"},
    )
    assert r.status_code in (200, 400, 422), (
        f"Null content вызвал неожиданный статус: {r.status_code}"
    )
    assert r.status_code != 500


def test_message_without_content_field_handled(client):
    """Отсутствие поля content → 422 от Pydantic или 400, не 500."""
    r = client.post(
        "/llm/chat",
        json={"messages": [{"role": "user"}], "api_key": "k"},
    )
    assert r.status_code in (200, 400, 422), (
        f"Отсутствие content вызвало неожиданный статус: {r.status_code}"
    )
    assert r.status_code != 500


def test_valid_multi_turn_conversation_handled(client):
    """Корректный многоходовой диалог с разными ролями обрабатывается без ошибок."""
    r = client.post(
        "/llm/chat",
        json={
            "messages": [
                {"role": "system", "content": "Ты помощник по исламу"},
                {"role": "user", "content": "Что такое халяль?"},
                {"role": "assistant", "content": "Халяль — это дозволенное."},
                {"role": "user", "content": "А харам?"},
            ],
            "api_key": "test-key",
        },
    )
    assert r.status_code == 200
    assert "reply" in r.json()


def test_unicode_and_special_chars_in_message_handled(client):
    """Unicode, арабский текст и спецсимволы в content не вызывают ошибок."""
    r = client.post(
        "/llm/chat",
        json={
            "messages": [
                {
                    "role": "user",
                    "content": "حَلَال؟ \u0000 €£¥ <>&\"' \u200b\ufffd",
                }
            ],
            "api_key": "test-key",
        },
    )
    assert r.status_code in (200, 400, 422)
    assert r.status_code != 500
