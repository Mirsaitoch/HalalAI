"""Сервисы для работы с LLM моделями."""

from .local_llm import LocalLLM
from .remote_llm import (
    call_remote_llm,
    get_remote_skip_reason,
    select_remote_model,
    should_use_remote_llm,
)

__all__ = [
    "LocalLLM",
    "should_use_remote_llm",
    "get_remote_skip_reason",
    "select_remote_model",
    "call_remote_llm",
]
