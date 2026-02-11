"""Кастомные исключения приложения."""


class HalalAIException(Exception):
    """Базовое исключение для всех ошибок HalalAI."""

    pass


class ModelNotLoadedException(HalalAIException):
    """Модель не загружена."""

    pass


class RAGNotInitializedException(HalalAIException):
    """RAG pipeline не инициализирован."""

    pass


class InvalidPromptException(HalalAIException):
    """Невалидный промпт."""

    pass


class RemoteLLMException(HalalAIException):
    """Ошибка при обращении к удаленной LLM."""

    pass


class TimeoutException(HalalAIException):
    """Превышено время ожидания."""

    pass
