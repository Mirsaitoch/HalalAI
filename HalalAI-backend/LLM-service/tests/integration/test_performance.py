"""4.4.3 Проверка производительности LLM-сервиса.

Проверяет, что эндпоинты отвечают в рамках установленных SLA при замоканных
зависимостях (без реальных вызовов OpenRouter / векторного хранилища).
"""
import time

import pytest

# SLA в миллисекундах
HEALTH_SLA_MS = 100
INFO_SLA_MS = 100
CHAT_SLA_MS = 2_000


# ── Одиночные запросы ─────────────────────────────────────────────────────────

def test_health_endpoint_responds_within_sla(client):
    start = time.perf_counter()
    r = client.get("/llm/health")
    elapsed_ms = (time.perf_counter() - start) * 1000

    assert r.status_code == 200
    assert elapsed_ms < HEALTH_SLA_MS, (
        f"health превысил SLA: {elapsed_ms:.1f} мс > {HEALTH_SLA_MS} мс"
    )


def test_info_endpoint_responds_within_sla(client):
    start = time.perf_counter()
    r = client.get("/llm/info")
    elapsed_ms = (time.perf_counter() - start) * 1000

    assert r.status_code == 200
    assert elapsed_ms < INFO_SLA_MS, (
        f"info превысил SLA: {elapsed_ms:.1f} мс > {INFO_SLA_MS} мс"
    )


def test_chat_endpoint_responds_within_sla(client):
    start = time.perf_counter()
    r = client.post(
        "/llm/chat",
        json={
            "messages": [{"role": "user", "content": "Вопрос о халяле"}],
            "api_key": "test-key",
        },
    )
    elapsed_ms = (time.perf_counter() - start) * 1000

    assert r.status_code == 200
    assert elapsed_ms < CHAT_SLA_MS, (
        f"chat превысил SLA: {elapsed_ms:.1f} мс > {CHAT_SLA_MS} мс"
    )


def test_root_redirect_responds_within_sla(client):
    start = time.perf_counter()
    r = client.get("/")
    elapsed_ms = (time.perf_counter() - start) * 1000

    assert r.status_code == 200
    assert elapsed_ms < INFO_SLA_MS, (
        f"root превысил SLA: {elapsed_ms:.1f} мс > {INFO_SLA_MS} мс"
    )


# ── Повторные запросы — деградации нет ───────────────────────────────────────

def test_health_repeated_10_times_all_within_sla(client):
    """Среднее время 10 последовательных запросов к health не должно деградировать."""
    times = []
    for _ in range(10):
        start = time.perf_counter()
        r = client.get("/llm/health")
        times.append((time.perf_counter() - start) * 1000)
        assert r.status_code == 200

    avg_ms = sum(times) / len(times)
    max_ms = max(times)
    assert max_ms < HEALTH_SLA_MS * 3, (
        f"Максимальное время health при повторных запросах: {max_ms:.1f} мс"
    )
    assert avg_ms < HEALTH_SLA_MS, (
        f"Среднее время health при повторных запросах: {avg_ms:.1f} мс > {HEALTH_SLA_MS} мс"
    )


def test_chat_repeated_5_times_all_within_sla(client):
    """5 последовательных запросов к chat должны укладываться в SLA."""
    for i in range(5):
        start = time.perf_counter()
        r = client.post(
            "/llm/chat",
            json={
                "messages": [{"role": "user", "content": f"Вопрос {i}"}],
                "api_key": "test-key",
            },
        )
        elapsed_ms = (time.perf_counter() - start) * 1000
        assert r.status_code == 200, f"Запрос {i} вернул {r.status_code}"
        assert elapsed_ms < CHAT_SLA_MS, (
            f"Запрос {i}: chat превысил SLA: {elapsed_ms:.1f} мс > {CHAT_SLA_MS} мс"
        )
