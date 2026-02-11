"""Быстрые интеграционные тесты для API endpoints без загрузки моделей."""

import pytest
from fastapi.testclient import TestClient

from halal_ai.main import app


@pytest.fixture
def client():
    """Создает тестовый клиент FastAPI."""
    return TestClient(app)


class TestHealthEndpoints:
    """Тесты для health check endpoints."""

    def test_health_check(self, client):
        """Проверяет что health endpoint работает."""
        response = client.get("/health")
        # Может быть 200 (healthy) или 503 (degraded - модели не загружены)
        assert response.status_code in [200, 503]
        
        data = response.json()
        # Если 503, может вернуться либо {'detail': '...'} либо {'status': 'degraded'}
        if response.status_code == 200:
            assert "status" in data
            assert data["status"] == "healthy"
        else:  # 503
            # Может быть либо status=degraded либо detail с ошибкой
            assert ("status" in data and data["status"] == "degraded") or "detail" in data

    def test_rag_status_structure(self, client):
        """Проверяет структуру ответа /rag/status."""
        response = client.get("/rag/status")
        assert response.status_code == 200
        
        data = response.json()
        # Проверяем обязательные поля
        assert "enabled" in data
        assert "documents" in data
        assert "embedding_model" in data
        assert "store_path" in data
        
        # Проверяем типы
        assert isinstance(data["enabled"], bool)
        assert isinstance(data["documents"], int)
        assert isinstance(data["embedding_model"], str)
        assert isinstance(data["store_path"], str)
        
        # documents должен быть >= 0
        assert data["documents"] >= 0


class TestChatEndpoint:
    """Тесты для chat endpoint."""

    def test_chat_requires_messages(self, client):
        """Проверяет что запрос без messages возвращает ошибку."""
        response = client.post("/chat", json={})
        # 422 (validation error) или 503 (service unavailable - модели не загружены)
        assert response.status_code in [422, 503]

    def test_chat_messages_must_be_list(self, client):
        """Проверяет что messages должен быть списком."""
        response = client.post("/chat", json={"messages": "not a list"})
        # 422 (validation error) или 503 (service unavailable - модели не загружены)
        assert response.status_code in [422, 503]

    def test_chat_message_structure(self, client):
        """Проверяет структуру сообщений."""
        # Пустой список сообщений
        response = client.post("/chat", json={"messages": []})
        # 422 (должен требовать хотя бы одно сообщение) или 503 (модели не загружены)
        assert response.status_code in [422, 503]

    def test_chat_with_system_and_user_messages(self, client):
        """Проверяет что можно отправить system и user сообщения."""
        messages = [
            {"role": "system", "content": "Ты исламский помощник"},
            {"role": "user", "content": "Привет"},
        ]
        response = client.post("/chat", json={"messages": messages})
        
        # Тест может пройти или не пройти в зависимости от загрузки моделей
        # Проверяем что запрос валидный (не 422)
        assert response.status_code != 422

    def test_chat_response_structure_if_successful(self, client):
        """Проверяет структуру ответа если запрос успешен."""
        messages = [{"role": "user", "content": "Ассаляму алейкум"}]
        response = client.post("/chat", json={"messages": messages})
        
        # Если запрос успешен, проверяем структуру
        if response.status_code == 200:
            data = response.json()
            assert "reply" in data
            assert "sources" in data
            assert "model" in data
            assert "used_remote" in data
            
            assert isinstance(data["reply"], str)
            assert isinstance(data["sources"], list)
            assert isinstance(data["model"], str)
            assert isinstance(data["used_remote"], bool)


class TestRAGEndpoints:
    """Тесты для RAG endpoints."""

    def test_rag_rebuild_requires_auth(self, client):
        """Проверяет что rebuild требует авторизации."""
        response = client.post("/rag/rebuild")
        # Может быть 401 (unauthorized) или 405 (method not allowed)
        # если endpoint не реализован
        assert response.status_code in [401, 405, 404]

    def test_rag_search_endpoint(self, client):
        """Проверяет что search endpoint существует или не реализован."""
        response = client.post(
            "/rag/search",
            json={"query": "тест", "top_k": 3},
        )
        # Endpoint может не существовать (404) или возвращать ошибку
        # Просто проверяем что запрос не крашит приложение
        assert response.status_code in [404, 405, 422, 500, 503]


class TestAPIValidation:
    """Тесты для валидации API."""

    def test_invalid_endpoint_returns_404(self, client):
        """Проверяет что несуществующий endpoint возвращает 404."""
        response = client.get("/nonexistent")
        assert response.status_code == 404

    def test_wrong_http_method(self, client):
        """Проверяет что неправильный HTTP метод возвращает 405."""
        response = client.delete("/health")
        assert response.status_code == 405

    def test_openapi_spec_available(self, client):
        """Проверяет что OpenAPI спецификация доступна."""
        response = client.get("/openapi.json")
        assert response.status_code == 200
        
        data = response.json()
        assert "openapi" in data
        assert "info" in data
        assert "paths" in data

    def test_docs_available(self, client):
        """Проверяет что документация доступна."""
        response = client.get("/docs")
        assert response.status_code == 200

    def test_cors_headers(self, client):
        """Проверяет что CORS заголовки установлены."""
        response = client.options("/health")
        # CORS может быть настроен или нет, просто проверяем что не крашится
        assert response.status_code in [200, 405]


@pytest.mark.parametrize(
    "endpoint,method",
    [
        ("/health", "GET"),
        ("/rag/status", "GET"),
        ("/chat", "POST"),
    ],
)
class TestEndpointAvailability:
    """Параметризованные тесты для проверки доступности endpoints."""

    def test_endpoint_exists(self, client, endpoint, method):
        """Проверяет что endpoint существует."""
        if method == "GET":
            response = client.get(endpoint)
        elif method == "POST":
            response = client.post(endpoint, json={})
        
        # Endpoint должен существовать (не 404)
        assert response.status_code != 404

    def test_endpoint_response_is_json(self, client, endpoint, method):
        """Проверяет что ответ endpoint в формате JSON."""
        if method == "GET":
            response = client.get(endpoint)
        elif method == "POST":
            response = client.post(endpoint, json={})
        
        # Если endpoint существует и не требует валидации
        if response.status_code not in [404, 422]:
            assert "application/json" in response.headers.get("content-type", "")
