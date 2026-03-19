"""Конфигурация приложения из переменных окружения."""

import logging
import os
from pathlib import Path
from typing import List, Optional

logger = logging.getLogger(__name__)

# Базовая директория проекта
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent


class LLMConfig:
    """Общая конфигурация для LLM запросов."""

    MAX_NEW_TOKENS: int = int(os.getenv("LLM_MAX_TOKENS", "6144"))
    MIN_NEW_TOKENS: int = 16
    TEMPERATURE: float = float(os.getenv("LLM_TEMPERATURE", "0.4"))
    TOP_P: float = float(os.getenv("LLM_TOP_P", "0.85"))
    REQUEST_TIMEOUT_SECONDS: int = int(os.getenv("LLM_REQUEST_TIMEOUT_SECONDS", "180"))


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
    API_KEY: str = os.getenv("REMOTE_LLM_API_KEY", "")
    MODEL: str = os.getenv("REMOTE_LLM_MODEL", "meta-llama/llama-3.3-70b-instruct:free")
    BASE_URL: Optional[str] = os.getenv("REMOTE_LLM_BASE_URL", "https://openrouter.ai/api/v1")
    REFERER: Optional[str] = os.getenv("REMOTE_LLM_REFERER")
    APP_TITLE: str = os.getenv("REMOTE_LLM_APP_TITLE", "HalalAI Client")

    # Разрешенные модели
    _allowed_env = os.getenv("REMOTE_LLM_ALLOWED_MODELS")
    _default_allowed = [
        "meta-llama/llama-3.3-70b-instruct:free",
        "mistralai/mistral-small-3.1-24b-instruct:free",
        "google/gemma-3-27b-it:free",
        "qwen/qwen3-4b:free",
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
