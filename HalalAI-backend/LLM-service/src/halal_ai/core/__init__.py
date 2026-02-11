"""Модуль core - конфигурация, константы и исключения."""

from .config import BASE_DIR, RAGConfig, RemoteLLMConfig, llm_config, rag_config, remote_llm_config
from .constants import (
    ALLOWED_MESSAGE_ROLES,
    DEFAULT_CHUNK_OVERLAP,
    DEFAULT_CHUNK_SIZE,
    DEFAULT_SYSTEM_PROMPT,
    HALAL_SAFETY_PROMPT,
    MAX_CHUNK_SIZE,
    MAX_SYSTEM_PROMPT_LENGTH,
    MIN_CHUNK_SIZE,
    QUESTION_RATIO_THRESHOLD,
    RAG_INSTRUCTION_PROMPT,
)
from .exceptions import (
    HalalAIException,
    InvalidPromptException,
    ModelNotLoadedException,
    RAGNotInitializedException,
    RemoteLLMException,
    TimeoutException,
)

__all__ = [
    # Config
    "BASE_DIR",
    "llm_config",
    "rag_config",
    "remote_llm_config",
    "RAGConfig",
    "RemoteLLMConfig",
    # Constants
    "ALLOWED_MESSAGE_ROLES",
    "DEFAULT_SYSTEM_PROMPT",
    "HALAL_SAFETY_PROMPT",
    "RAG_INSTRUCTION_PROMPT",
    "MAX_SYSTEM_PROMPT_LENGTH",
    "QUESTION_RATIO_THRESHOLD",
    "DEFAULT_CHUNK_SIZE",
    "DEFAULT_CHUNK_OVERLAP",
    "MIN_CHUNK_SIZE",
    "MAX_CHUNK_SIZE",
    # Exceptions
    "HalalAIException",
    "ModelNotLoadedException",
    "RAGNotInitializedException",
    "InvalidPromptException",
    "RemoteLLMException",
    "TimeoutException",
]
