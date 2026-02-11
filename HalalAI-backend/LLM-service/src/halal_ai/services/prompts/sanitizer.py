"""Санитизация и валидация промптов."""

from halal_ai.core import DEFAULT_SYSTEM_PROMPT, MAX_SYSTEM_PROMPT_LENGTH, QUESTION_RATIO_THRESHOLD


def sanitize_system_prompt_content(content: str) -> str:
    """
    Санитизирует системный промпт от пользователя.
    
    Удаляет подозрительные символы и проверяет на валидность.
    Если промпт выглядит подозрительно (слишком много вопросов, слишком короткий и т.д.),
    возвращает дефолтный системный промпт.
    """
    text = (content or "").strip()
    if not text:
        return DEFAULT_SYSTEM_PROMPT

    # Удаляем кавычки если промпт весь в кавычках
    if text.startswith('"') and text.endswith('"'):
        text = text[1:-1]
    
    # Очищаем от лишних символов
    text = text.strip().rstrip(";").strip()
    text = text.replace(r"\"", '"').strip()

    # Проверяем на подозрительное количество вопросительных знаков
    question_ratio = text.count("?") / max(len(text), 1)
    if question_ratio > QUESTION_RATIO_THRESHOLD or "??" in text:
        return DEFAULT_SYSTEM_PROMPT

    # Слишком короткий промпт подозрителен (меньше 10 символов)
    if len(text) < 10:
        return DEFAULT_SYSTEM_PROMPT
    
    # Слишком длинный промпт подозрителен
    if len(text) > MAX_SYSTEM_PROMPT_LENGTH:
        return DEFAULT_SYSTEM_PROMPT

    return text
