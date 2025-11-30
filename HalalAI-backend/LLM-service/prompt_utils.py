from typing import List, Dict

from transformers import AutoTokenizer

from config import LOG_PROMPT_ENABLED, LOG_PROMPT_MAX_CHARS, DEFAULT_SYSTEM_PROMPT


def build_prompt_text(tokenizer: AutoTokenizer, messages: List[Dict[str, str]]) -> str:
    return tokenizer.apply_chat_template(
        messages,
        tokenize=False,
        add_generation_prompt=True,
        enable_thinking=False,
    )


def log_prompt_if_needed(logger, prompt_text: str):
    if not LOG_PROMPT_ENABLED:
        return
    truncated = ""
    if len(prompt_text) > LOG_PROMPT_MAX_CHARS:
        prompt_text = prompt_text[:LOG_PROMPT_MAX_CHARS]
        truncated = "\n...[truncated]"
    logger.info("LLM prompt payload:\n%s%s", prompt_text, truncated)


def sanitize_system_prompt_content(content: str) -> str:
    text = (content or "").strip()
    if not text:
        return DEFAULT_SYSTEM_PROMPT

    if text.startswith('"') and text.endswith('"'):
        text = text[1:-1]
    text = text.strip().rstrip(";").strip()
    text = text.replace(r"\"", '"').strip()

    question_ratio = text.count("?") / max(len(text), 1)
    if question_ratio > 0.25 or "??" in text:
        return DEFAULT_SYSTEM_PROMPT

    if len(text) < 40:
        return DEFAULT_SYSTEM_PROMPT

    return text

