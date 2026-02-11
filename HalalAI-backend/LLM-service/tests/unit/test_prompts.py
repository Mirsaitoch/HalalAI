"""Тесты для модуля prompts."""

import pytest

from halal_ai.core import DEFAULT_SYSTEM_PROMPT, HALAL_SAFETY_PROMPT
from halal_ai.services.prompts import (
    ensure_system_prompt,
    inject_halal_guardrail,
    inject_rag_context,
    inject_surah_guardrail,
    sanitize_system_prompt_content,
)


@pytest.fixture
def sample_rag_sources():
    """Пример RAG источников."""
    return [
        {
            "id": "surah_2_ayah_1_3",
            "text": "В имя Аллаха...",
            "metadata": {
                "surah": 2,
                "surah_name_ru": "Аль-Бакара",
                "ayah_from": 1,
                "ayah_to": 3,
            },
            "score": 0.95,
        }
    ]


class TestSanitizeSystemPrompt:
    """Тесты для sanitize_system_prompt_content."""

    def test_empty_prompt_returns_default(self):
        """Пустой промпт возвращает дефолтный."""
        assert sanitize_system_prompt_content("") == DEFAULT_SYSTEM_PROMPT
        assert sanitize_system_prompt_content(None) == DEFAULT_SYSTEM_PROMPT

    def test_removes_quotes(self):
        """Удаляет кавычки вокруг промпта."""
        prompt = '"Test prompt without quotes"'
        result = sanitize_system_prompt_content(prompt)
        assert result != DEFAULT_SYSTEM_PROMPT
        assert '"' not in result

    def test_too_many_questions_returns_default(self):
        """Слишком много вопросительных знаков возвращает дефолт."""
        prompt = "????????"
        assert sanitize_system_prompt_content(prompt) == DEFAULT_SYSTEM_PROMPT

    def test_short_prompt_returns_default(self):
        """Слишком короткий промпт возвращает дефолт."""
        prompt = "Hi"
        assert sanitize_system_prompt_content(prompt) == DEFAULT_SYSTEM_PROMPT

    def test_valid_prompt_passes_through(self):
        """Валидный промпт проходит санитизацию."""
        prompt = "You are a helpful assistant. Answer questions about Islam."
        result = sanitize_system_prompt_content(prompt)
        assert result == prompt


class TestEnsureSystemPrompt:
    """Тесты для ensure_system_prompt."""

    def test_adds_default_if_missing(self):
        """Добавляет дефолтный system промпт если отсутствует."""
        messages = [{"role": "user", "content": "Hello"}]
        result = ensure_system_prompt(messages)
        assert result[0]["role"] == "system"
        assert result[0]["content"] == DEFAULT_SYSTEM_PROMPT

    def test_sanitizes_existing_system_prompt(self):
        """Санитизирует существующий system промпт."""
        messages = [
            {"role": "system", "content": "Hi"},  # слишком короткий
            {"role": "user", "content": "Hello"},
        ]
        result = ensure_system_prompt(messages)
        assert result[0]["content"] == DEFAULT_SYSTEM_PROMPT

    def test_keeps_valid_system_prompt(self):
        """Сохраняет валидный system промпт."""
        valid_prompt = "You are a helpful Islamic assistant. Answer questions truthfully."
        messages = [
            {"role": "system", "content": valid_prompt},
            {"role": "user", "content": "Hello"},
        ]
        result = ensure_system_prompt(messages)
        assert result[0]["content"] == valid_prompt


class TestInjectHalalGuardrail:
    """Тесты для inject_halal_guardrail."""

    def test_injects_safety_prompt(self):
        """Добавляет safety промпт."""
        messages = [
            {"role": "system", "content": "System"},
            {"role": "user", "content": "Question"},
        ]
        result = inject_halal_guardrail(messages)
        assert len(result) == 3
        assert result[1]["role"] == "system"
        assert result[1]["content"] == HALAL_SAFETY_PROMPT

    def test_adds_at_beginning_if_no_system(self):
        """Добавляет в начало если нет system промпта."""
        messages = [{"role": "user", "content": "Question"}]
        result = inject_halal_guardrail(messages)
        assert result[0]["role"] == "system"
        assert result[0]["content"] == HALAL_SAFETY_PROMPT


class TestInjectSurahGuardrail:
    """Тесты для inject_surah_guardrail."""

    def test_injects_single_surah_guardrail(self):
        """Добавляет guardrail для одной суры."""
        messages = [{"role": "user", "content": "Question"}]
        result = inject_surah_guardrail(messages, [2])
        assert len(result) == 2
        assert "Аль-Бакара" in result[0]["content"] or "сура 2" in result[0]["content"]

    def test_injects_multiple_surah_guardrail(self):
        """Добавляет guardrail для нескольких сур."""
        messages = [{"role": "user", "content": "Question"}]
        result = inject_surah_guardrail(messages, [2, 3, 5])
        assert len(result) == 2
        assert "сурам" in result[0]["content"].lower()

    def test_returns_unchanged_if_no_surahs(self):
        """Возвращает без изменений если нет сур."""
        messages = [{"role": "user", "content": "Question"}]
        result = inject_surah_guardrail(messages, [])
        assert result == messages


class TestInjectRAGContext:
    """Тесты для inject_rag_context."""

    def test_injects_rag_context(self, sample_rag_sources):
        """Добавляет RAG контекст."""
        messages = [{"role": "user", "content": "Question"}]
        result = inject_rag_context(messages, sample_rag_sources)
        assert len(result) == 2
        assert result[0]["role"] == "system"
        assert "Аль-Бакара" in result[0]["content"]
        assert "В имя Аллаха" in result[0]["content"]

    def test_returns_unchanged_if_no_context(self):
        """Возвращает без изменений если нет контекста."""
        messages = [{"role": "user", "content": "Question"}]
        result = inject_rag_context(messages, [])
        assert result == messages

    def test_skips_empty_contexts(self):
        """Пропускает пустые контексты."""
        contexts = [
            {"text": "", "metadata": {}},
            {"text": "Valid text", "metadata": {"surah": 1}},
        ]
        messages = [{"role": "user", "content": "Question"}]
        result = inject_rag_context(messages, contexts)
        assert "Valid text" in result[0]["content"]
        assert len([c for c in result[0]["content"].split("\n") if c.strip()]) >= 2
