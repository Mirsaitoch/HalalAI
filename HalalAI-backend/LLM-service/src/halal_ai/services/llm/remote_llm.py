"""Сервис для работы с удаленной LLM через OpenAI-compatible API."""

import logging
from typing import Any, Dict, List, Optional, Tuple

from halal_ai.core import llm_config, remote_llm_config
from halal_ai.core.exceptions import RemoteLLMException

logger = logging.getLogger(__name__)


def should_use_remote_llm(api_key: Optional[str]) -> bool:
    """
    Проверяет, нужно ли использовать удаленную LLM.
    
    Args:
        api_key: API ключ пользователя
        
    Returns:
        True если нужно использовать удаленную LLM
    """
    return bool(api_key and remote_llm_config.ENABLED)


def get_remote_skip_reason(api_key: Optional[str]) -> Optional[str]:
    """
    Возвращает причину, по которой remote LLM не будет вызвана.
    
    Args:
        api_key: API ключ пользователя
        
    Returns:
        Строка с причиной или None если можно использовать
    """
    if not api_key:
        return "api_key не передан"
    if not remote_llm_config.ENABLED:
        return "REMOTE_LLM_ENABLED=false"
    return None


def select_remote_model(user_model: Optional[str]) -> str:
    """
    Выбирает удалённую модель с учётом разрешённого списка.
    
    Args:
        user_model: Модель запрошенная пользователем
        
    Returns:
        Название модели для использования
        
    Raises:
        RemoteLLMException: Если модель не разрешена
    """
    candidate = (user_model or "").strip() or remote_llm_config.MODEL
    
    # Убираем префикс если он есть
    if candidate.startswith("remote:") or candidate.startswith("local:"):
        candidate = candidate.split(":", 1)[1].strip()
    
    # Проверяем на "none"
    if candidate.lower() == "none":
        raise RemoteLLMException("remote_model не задан")
    
    # Проверяем разрешенные модели
    if remote_llm_config.ALLOWED_MODELS and candidate not in remote_llm_config.ALLOWED_MODELS:
        raise RemoteLLMException(
            f"remote_model '{candidate}' не разрешен. "
            f"Доступные: {', '.join(remote_llm_config.ALLOWED_MODELS)}"
        )
    
    return candidate


def call_remote_llm(
    messages: List[Dict[str, str]],
    max_tokens: int,
    api_key: str,
    model_override: Optional[str] = None,
) -> str:
    """
    Вызывает удаленную LLM через OpenAI-compatible API.
    
    Args:
        messages: История сообщений
        max_tokens: Максимальное количество токенов
        api_key: API ключ
        model_override: Переопределение модели
        
    Returns:
        Сгенерированный текст
        
    Raises:
        RemoteLLMException: При ошибке вызова API
    """
    try:
        from openai import OpenAI
    except ImportError as exc:
        logger.error("Не установлен пакет openai для удаленного инференса: %s", exc)
        raise RemoteLLMException("Remote LLM support is not available on the server") from exc

    client_kwargs: Dict[str, Any] = {"api_key": api_key}
    if remote_llm_config.BASE_URL:
        client_kwargs["base_url"] = remote_llm_config.BASE_URL

    default_headers: Dict[str, str] = {}
    if remote_llm_config.REFERER:
        default_headers["HTTP-Referer"] = remote_llm_config.REFERER
        default_headers["Referer"] = remote_llm_config.REFERER
    if remote_llm_config.APP_TITLE:
        default_headers["X-Title"] = remote_llm_config.APP_TITLE
    if default_headers:
        client_kwargs["default_headers"] = default_headers

    client = OpenAI(**client_kwargs)
    chat_messages = [{"role": msg["role"], "content": msg["content"]} for msg in messages]

    model_to_use = model_override or remote_llm_config.MODEL
    logger.info(
        "Проксируем запрос в удаленную LLM (model=%s, base_url=%s, title=%s).",
        model_to_use,
        remote_llm_config.BASE_URL or "default",
        remote_llm_config.APP_TITLE,
    )

    try:
        response = client.chat.completions.create(
            model=model_to_use,
            messages=chat_messages,
            temperature=llm_config.TEMPERATURE,
            top_p=llm_config.TOP_P,
            max_tokens=max_tokens,
            stream=False,
            timeout=llm_config.REQUEST_TIMEOUT_SECONDS,
        )
    except Exception as exc:
        logger.error("Ошибка при обращении к удаленной модели: %s", exc)
        raise RemoteLLMException(f"Remote LLM error: {exc}") from exc

    choice = response.choices[0]
    finish_reason = getattr(choice, "finish_reason", None)
    content_value, source = _extract_choice_content(choice)

    if not content_value:
        logger.info(
            "Удаленная LLM вернула пустой ответ (finish_reason=%s). Полный ответ: %s",
            finish_reason,
            response,
        )
        raise RemoteLLMException("Remote LLM returned empty response")

    if source != "content":
        logger.info(
            "Удаленная LLM вернула reasoning вместо финального ответа (source=%s, finish_reason=%s).",
            source,
            finish_reason,
        )

    if finish_reason == "length":
        logger.info("Удаленная LLM завершилась по длине (finish_reason=length). Возвращаем усеченный ответ.")

    return content_value


def _extract_choice_content(choice) -> Tuple[str, str]:
    """Извлекает контент из ответа модели."""
    content = getattr(choice.message, "content", None)
    text = _normalize_openrouter_content(content)
    if text:
        return text, "content"

    reasoning = getattr(choice.message, "reasoning", None)
    text = _normalize_openrouter_content(reasoning)
    if text:
        return text, "reasoning"

    reasoning_details = getattr(choice.message, "reasoning_details", None)
    if isinstance(reasoning_details, list):
        text = _normalize_openrouter_content(reasoning_details)
        if text:
            return text, "reasoning_details"

    return "", "none"


def _normalize_openrouter_content(content) -> str:
    """Нормализует контент из разных форматов OpenRouter."""
    if isinstance(content, str):
        return content.strip()
    
    if isinstance(content, list):
        parts: List[str] = []
        for part in content:
            if isinstance(part, str):
                parts.append(part)
                continue
            if isinstance(part, dict):
                candidate = part.get("text") or part.get("value") or part.get("content")
                if isinstance(candidate, list):
                    candidate = "".join(
                        frag.get("text", "") if isinstance(frag, dict) else str(frag) for frag in candidate
                    )
                if isinstance(candidate, str):
                    parts.append(candidate)
        return "".join(parts).strip()
    
    if isinstance(content, dict):
        for key in ("text", "value", "content"):
            value = content.get(key)
            if isinstance(value, str):
                return value.strip()
    
    return ""
