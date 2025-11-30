import logging
from typing import Any, Dict, List, Optional, Tuple

from config import (
    LLM_TEMPERATURE,
    LLM_TOP_P,
    REMOTE_LLM_APP_TITLE,
    REMOTE_LLM_BASE_URL,
    REMOTE_LLM_ENABLED,
    REMOTE_LLM_MODEL,
    REMOTE_LLM_REFERER,
)

logger = logging.getLogger(__name__)


def should_use_remote_llm(api_key: Optional[str]) -> bool:
    return bool(api_key and REMOTE_LLM_ENABLED)


def call_remote_llm(
    messages: List[Dict[str, str]],
    max_tokens: int,
    api_key: str,
    model_override: Optional[str] = None,
) -> str:
    try:
        from openai import OpenAI
    except ImportError as exc:
        logger.error("Не установлен пакет openai для удаленного инференса: %s", exc)
        raise RuntimeError("Remote LLM support is not available on the server") from exc

    client_kwargs: Dict[str, Any] = {"api_key": api_key}
    if REMOTE_LLM_BASE_URL:
        client_kwargs["base_url"] = REMOTE_LLM_BASE_URL

    default_headers: Dict[str, str] = {}
    if REMOTE_LLM_REFERER:
        default_headers["HTTP-Referer"] = REMOTE_LLM_REFERER
    if REMOTE_LLM_APP_TITLE:
        default_headers["X-Title"] = REMOTE_LLM_APP_TITLE
    if default_headers:
        client_kwargs["default_headers"] = default_headers

    client = OpenAI(**client_kwargs)
    chat_messages = [{"role": msg["role"], "content": msg["content"]} for msg in messages]

    logger.info(
        "Проксируем запрос в OpenRouter (model=%s, base_url=%s, title=%s).",
        model_override or REMOTE_LLM_MODEL,
        REMOTE_LLM_BASE_URL or "default",
        REMOTE_LLM_APP_TITLE,
    )

    try:
        response = client.chat.completions.create(
            model=model_override or REMOTE_LLM_MODEL,
            messages=chat_messages,
            temperature=LLM_TEMPERATURE,
            top_p=LLM_TOP_P,
            max_tokens=max_tokens,
            stream=False,
        )
    except Exception as exc:
        logger.error("Ошибка при обращении к удаленной модели: %s", exc)
        raise RuntimeError(f"Remote LLM error: {exc}") from exc

    choice = response.choices[0]
    finish_reason = getattr(choice, "finish_reason", None)
    content_value, source = _extract_choice_content(choice)

    if not content_value:
        logger.info(
            "Удаленная LLM вернула пустой ответ (finish_reason=%s). Полный ответ: %s",
            finish_reason,
            response,
        )
        raise RuntimeError("Remote LLM returned empty response")

    if source != "content" or finish_reason == "length":
        logger.info(
            "Удаленная LLM вернула reasoning вместо финального ответа (source=%s, finish_reason=%s).",
            source,
            finish_reason,
        )
        raise RuntimeError("Remote LLM returned reasoning instead of final answer")

    return content_value


def _extract_choice_content(choice) -> Tuple[str, str]:
    content = getattr(choice.message, "content", None)
    text = _normalize_openrouter_content(content)
    if text:
        return text, "content"

    reasoning = getattr(choice.message, "reasoning", None)
    text = _normalize_openrouter_content(reasoning)
    if text:
        return _cleanup_reasoning_text(text), "reasoning"

    reasoning_details = getattr(choice.message, "reasoning_details", None)
    if isinstance(reasoning_details, list):
        text = _normalize_openrouter_content(reasoning_details)
        if text:
            return _cleanup_reasoning_text(text), "reasoning_details"

    return "", "none"


def _normalize_openrouter_content(content) -> str:
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
                        frag.get("text", "") if isinstance(frag, dict) else str(frag)
                        for frag in candidate
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


def _cleanup_reasoning_text(text: str) -> str:
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    if paragraphs:
        head = paragraphs[0].lower()
        if head.startswith(("хм", "hmm", "let me", "окей", "окey")):
            paragraphs = paragraphs[1:] or paragraphs
    cleaned = "\n\n".join(paragraphs).strip()
    return cleaned or text.strip()

