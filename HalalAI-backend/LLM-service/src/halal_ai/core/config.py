"""Конфигурация приложения из переменных окружения."""

import logging
import os
from pathlib import Path
from typing import List, Optional

logger = logging.getLogger(__name__)

# Базовая директория проекта
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent


class LLMConfig:
    """Конфигурация для локальной LLM модели."""

    MODEL_NAME: str = os.getenv("LLM_MODEL_NAME", "Qwen/Qwen3-1.7B")
    DEFAULT_MAX_NEW_TOKENS: int = int(os.getenv("LLM_DEFAULT_MAX_TOKENS", "4096"))
    MAX_NEW_TOKENS: int = int(os.getenv("LLM_MAX_TOKENS", "6144"))
    MIN_NEW_TOKENS: int = 16
    TEMPERATURE: float = float(os.getenv("LLM_TEMPERATURE", "0.4"))
    TOP_P: float = float(os.getenv("LLM_TOP_P", "0.85"))
    REQUEST_TIMEOUT_SECONDS: int = int(os.getenv("LLM_REQUEST_TIMEOUT_SECONDS", "180"))

    # История сообщений
    MAX_HISTORY_MESSAGES: int = 16
    MAX_HISTORY_TOKEN_LENGTH: int = 2048

    # Логирование промптов
    LOG_PROMPT_ENABLED: bool = os.getenv("LLM_LOG_PROMPT", "true").lower() in {"1", "true", "yes"}
    LOG_PROMPT_MAX_CHARS: int = int(os.getenv("LLM_LOG_PROMPT_MAX_CHARS", "4000"))


class RAGConfig:
    """Конфигурация для RAG системы."""

    ENABLED: bool = os.getenv("RAG_ENABLED", "true").lower() in {"1", "true", "yes"}
    EMBEDDING_MODEL: str = os.getenv(
        "RAG_EMBEDDING_MODEL", "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    )
    EMBEDDING_DEVICE: str = os.getenv("RAG_EMBEDDING_DEVICE", "cpu")
    VECTOR_STORE_PATH: str = os.getenv("RAG_STORE_PATH", str(BASE_DIR / "data" / "vector_store.pt"))
    DEFAULT_TOP_K: int = int(os.getenv("RAG_DEFAULT_TOP_K", "3"))
    SEARCH_TOP_K: int = int(os.getenv("RAG_SEARCH_TOP_K", "8"))


class RemoteLLMConfig:
    """Конфигурация для удаленной LLM (OpenAI-compatible API)."""

    ENABLED: bool = os.getenv("REMOTE_LLM_ENABLED", "true").lower() in {"1", "true", "yes"}
    MODEL: str = os.getenv("REMOTE_LLM_MODEL", "xiaomi/mimo-v2-flash:free")
    BASE_URL: Optional[str] = os.getenv("REMOTE_LLM_BASE_URL", "https://openrouter.ai/api/v1")
    REFERER: Optional[str] = os.getenv("REMOTE_LLM_REFERER")
    APP_TITLE: str = os.getenv("REMOTE_LLM_APP_TITLE", "HalalAI Client")

    # Разрешенные модели
    _allowed_env = os.getenv("REMOTE_LLM_ALLOWED_MODELS")
    _default_allowed = [
        "xiaomi/mimo-v2-flash:free",
        "tngtech/deepseek-r1t2-chimera:free",
        "gpt-4o-mini",
    ]
    ALLOWED_MODELS: List[str] = (
        [model.strip() for model in _allowed_env.split(",") if model.strip()]
        if _allowed_env is not None
        else _default_allowed
    )


# Singleton instances
llm_config = LLMConfig()
rag_config = RAGConfig()
remote_llm_config = RemoteLLMConfig()
