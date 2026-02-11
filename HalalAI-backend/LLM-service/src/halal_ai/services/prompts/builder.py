"""Построение промптов для LLM."""

import logging
from typing import Any, Dict, List

from transformers import AutoTokenizer

from halal_ai.core import (
    DEFAULT_SYSTEM_PROMPT,
    HALAL_SAFETY_PROMPT,
    RAG_INSTRUCTION_PROMPT,
    llm_config,
)
from halal_ai.services.prompts.sanitizer import sanitize_system_prompt_content
from halal_ai.utils import describe_surah, format_source_heading

logger = logging.getLogger(__name__)


def build_prompt_text(tokenizer: AutoTokenizer, messages: List[Dict[str, str]]) -> str:
    """
    Создает финальный промпт для модели используя chat template.
    
    Args:
        tokenizer: Токенизатор модели
        messages: Список сообщений с ролями
        
    Returns:
        Строка промпта готовая для генерации
    """
    return tokenizer.apply_chat_template(
        messages,
        tokenize=False,
        add_generation_prompt=True,
        enable_thinking=False,
    )


def log_prompt_if_needed(prompt_text: str) -> None:
    """Логирует промпт если включено в конфиге."""
    if not llm_config.LOG_PROMPT_ENABLED:
        return
    
    truncated = ""
    if len(prompt_text) > llm_config.LOG_PROMPT_MAX_CHARS:
        prompt_text = prompt_text[: llm_config.LOG_PROMPT_MAX_CHARS]
        truncated = "\n...[truncated]"
    
    logger.info("LLM prompt payload:\n%s%s", prompt_text, truncated)


def ensure_system_prompt(messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """
    Гарантирует наличие system-промпта и его санитизацию.
    
    Если первое сообщение не system - добавляет дефолтный.
    Если есть - санитизирует его содержимое.
    """
    if not messages:
        return [{"role": "system", "content": DEFAULT_SYSTEM_PROMPT}]
    
    first_role = messages[0].get("role")
    if first_role != "system":
        logger.info("Системный промпт отсутствует, добавляем дефолтный.")
        return [{"role": "system", "content": DEFAULT_SYSTEM_PROMPT}] + messages
    
    original_content = messages[0].get("content", "")
    sanitized = sanitize_system_prompt_content(original_content)
    
    if sanitized != original_content:
        logger.info("Получен пользовательский system prompt, выполняем санитизацию.")
    
    messages[0]["content"] = sanitized
    return messages


def inject_halal_guardrail(messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Добавляет обязательный safety-блок о хараме свинины."""
    if not messages:
        return [{"role": "system", "content": HALAL_SAFETY_PROMPT}]
    
    insert_idx = 1 if messages[0].get("role") == "system" else 0
    augmented = messages[:]
    augmented.insert(
        insert_idx,
        {"role": "system", "content": HALAL_SAFETY_PROMPT},
    )
    return augmented


def inject_surah_guardrail(messages: List[Dict[str, str]], surah_numbers: List[int]) -> List[Dict[str, str]]:
    """Вставляет guardrail для фиксации конкретных сур."""
    unique_numbers = sorted({num for num in surah_numbers if isinstance(num, int)})
    if not unique_numbers:
        return messages

    labels = [describe_surah(num) or f"Сура {num}" for num in unique_numbers]
    
    if len(unique_numbers) == 1:
        guard_text = (
            f"Вопрос относится исключительно к {labels[0]}. "
            "Никогда не упоминай другие номера сур и не придумывай фактов вне предоставленных источников."
        )
    else:
        joined = "; ".join(labels)
        guard_text = (
            f"Вопрос относится к следующим сурам: {joined}. "
            "Используй только эти номера и избегай упоминания любых других сур."
        )

    guard_message = {"role": "system", "content": guard_text}
    augmented = messages[:]
    insert_idx = 1 if augmented and augmented[0].get("role") == "system" else 0
    augmented.insert(insert_idx, guard_message)
    return augmented


def inject_rag_context(messages: List[Dict[str, str]], contexts: List[Dict[str, Any]]) -> List[Dict[str, str]]:
    """
    Добавляет контекст из RAG в начало истории.
    
    Улучшено: явно указывает доступные суры и аяты для предотвращения галлюцинаций.
    """
    if not contexts:
        return messages

    context_blocks = []
    available_citations = []  # Список доступных цитат
    
    for idx, ctx in enumerate(contexts, 1):
        text = (ctx.get("text") or "").strip()
        if not text:
            continue
        
        metadata = ctx.get("metadata") or {}
        heading = format_source_heading(metadata)
        
        # Добавляем явное указание номера источника
        block = f"[ИСТОЧНИК {idx}] {heading}\n{text}"
        context_blocks.append(block)
        
        # Собираем доступные цитаты
        surah = metadata.get("surah")
        if surah:
            ayah_range = metadata.get("ayah_range", "")
            if ayah_range:
                available_citations.append(f"сура {surah}, аяты {ayah_range}")

    if not context_blocks:
        return messages
    
    # Формируем список доступных цитат
    citations_list = ""
    if available_citations:
        citations_list = (
            "\n\nДОСТУПНЫЕ ЦИТАТЫ (используй ТОЛЬКО эти):\n" +
            "\n".join(f"• {cite}" for cite in available_citations)
        )
    
    rag_message = {
        "role": "system",
        "content": (
            f"{RAG_INSTRUCTION_PROMPT}"
            f"{citations_list}\n\n"
            "=== ИСТОЧНИКИ ===\n\n" +
            "\n\n".join(context_blocks)
        ),
    }

    augmented = messages[:]
    insert_idx = 1 if augmented and augmented[0].get("role") == "system" else 0
    augmented.insert(insert_idx, rag_message)
    return augmented
