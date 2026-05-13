"""Тесты для модуля helpers."""

import pytest

from halal_ai.utils import (
    build_rag_filters,
    chunk_text,
    extract_last_user_query,
    format_source_heading,
    serialize_sources,
)


class TestChunkText:
    """Тесты для chunk_text."""

    def test_small_text_returns_single_chunk(self):
        """Короткий текст возвращается как один чанк."""
        text = "Short text"
        result = chunk_text(text, chunk_size=100, chunk_overlap=10)
        assert len(result) == 1
        assert result[0] == text

    def test_chunks_long_text(self):
        """Длинный текст разбивается на чанки."""
        text = "a" * 1000
        result = chunk_text(text, chunk_size=100, chunk_overlap=10)
        assert len(result) > 1
        assert all(len(chunk) <= 100 for chunk in result)

    def test_empty_text_returns_empty_list(self):
        """Пустой текст возвращает пустой список."""
        assert chunk_text("", 100, 10) == []
        assert chunk_text(None, 100, 10) == []

    def test_normalizes_whitespace(self):
        """Нормализует пробелы."""
        text = "Text  with   multiple    spaces"
        result = chunk_text(text, chunk_size=100, chunk_overlap=10)
        assert "  " not in result[0]


class TestExtractLastUserQuery:
    """Тесты для extract_last_user_query."""

    def test_extracts_last_user_message(self):
        """Извлекает последнее сообщение пользователя."""
        messages = [
            {"role": "system", "content": "System"},
            {"role": "user", "content": "First question"},
            {"role": "assistant", "content": "Answer"},
            {"role": "user", "content": "Second question"},
        ]
        result = extract_last_user_query(messages)
        assert result == "Second question"

    def test_returns_empty_if_no_user_messages(self):
        """Возвращает пустую строку если нет user сообщений."""
        messages = [
            {"role": "system", "content": "System"},
            {"role": "assistant", "content": "Answer"},
        ]
        result = extract_last_user_query(messages)
        assert result == ""

    def test_handles_empty_list(self):
        """Обрабатывает пустой список."""
        assert extract_last_user_query([]) == ""


class TestBuildRAGFilters:
    """Тесты для build_rag_filters."""

    def test_extracts_surah_numbers(self):
        """Извлекает номера сур из запроса."""
        query = "Что сказано в суре 2 про веру?"
        result = build_rag_filters(query)
        assert "surah" in result
        assert 2 in result["surah"]

    def test_extracts_multiple_surahs(self):
        """Извлекает несколько номеров сур."""
        query = "Сура 2 и сура 5"
        result = build_rag_filters(query)
        assert 2 in result["surah"]
        assert 5 in result["surah"]

    def test_returns_empty_if_no_surahs(self):
        """Возвращает пустой словарь если нет сур."""
        query = "Общий вопрос про ислам"
        result = build_rag_filters(query)
        assert result == {}


class TestFormatSourceHeading:
    """Тесты для format_source_heading."""

    def test_formats_with_surah_and_ayah(self):
        """Форматирует заголовок с сурой и аятом."""
        metadata = {
            "surah": 2,
            "surah_name_ru": "Аль-Бакара",
            "ayah_from": 5,
            "ayah_to": 7,
        }
        result = format_source_heading(metadata)
        assert "Аль-Бакара" in result
        assert "5" in result and "7" in result

    def test_formats_single_ayah(self):
        """Форматирует одиночный аят."""
        metadata = {
            "surah": 1,
            "surah_name_ru": "Аль-Фатиха",
            "ayah_from": 1,
        }
        result = format_source_heading(metadata)
        assert "Аль-Фатиха" in result
        assert "Аят 1" in result

    def test_fallback_to_default(self):
        """Возвращает дефолт если нет метаданных."""
        result = format_source_heading({})
        assert result == "Источник"


class TestSerializeSources:
    """Тесты для serialize_sources."""

    def test_serializes_sources(self):
        """Сериализует источники."""
        sources = [
            {
                "id": "doc1",
                "score": 0.95432,
                "metadata": {"surah": 2},
            }
        ]
        result = serialize_sources(sources)
        assert len(result) == 1
        assert result[0]["id"] == "doc1"
        assert result[0]["score"] == 0.9543  # округлено до 4 знаков
        assert result[0]["metadata"]["surah"] == 2

    def test_handles_missing_fields(self):
        """Обрабатывает отсутствующие поля."""
        sources = [{"text": "some text"}]
        result = serialize_sources(sources)
        assert result[0]["id"] is None
        assert result[0]["score"] == 0.0
        assert result[0]["metadata"] == {}
