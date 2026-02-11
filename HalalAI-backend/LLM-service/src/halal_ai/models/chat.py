"""Pydantic модели для чата."""

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    """Сообщение в чате."""

    role: str = Field(..., description="Роль отправителя: system, user, assistant")
    content: str = Field(..., description="Текст сообщения")


class ChatRequest(BaseModel):
    """Запрос на генерацию ответа."""

    prompt: Optional[str] = Field(None, description="Простой промпт (альтернатива messages)")
    messages: Optional[List[ChatMessage]] = Field(None, description="История сообщений")
    max_tokens: Optional[int] = Field(1024, description="Максимальное количество токенов в ответе")
    use_rag: bool = Field(True, description="Использовать ли RAG для поиска контекста")
    rag_top_k: Optional[int] = Field(None, description="Количество контекстов из RAG")
    api_key: Optional[str] = Field(None, description="API ключ для удаленной LLM")
    remote_model: Optional[str] = Field(None, description="Название удаленной модели")


class ChatResponse(BaseModel):
    """Ответ от LLM."""

    reply: str = Field(..., description="Сгенерированный ответ")
    sources: Optional[List[Dict[str, Any]]] = Field(None, description="Источники из RAG")
    model: Optional[str] = Field(None, description="Использованная модель")
    used_remote: Optional[bool] = Field(None, description="Использовалась ли удаленная LLM")
    remote_error: Optional[str] = Field(None, description="Ошибка при обращении к удаленной LLM")


class RemoteTestRequest(BaseModel):
    """Запрос на тестирование удаленной LLM."""

    api_key: str = Field(..., description="API ключ")
    prompt: str = Field("Короткий пинг", description="Тестовый промпт")
    model: Optional[str] = Field(None, description="Модель для тестирования")
    max_tokens: int = Field(64, description="Максимальное количество токенов")
