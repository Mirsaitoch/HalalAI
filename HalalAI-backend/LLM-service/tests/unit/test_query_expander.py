"""Тесты для расширения и нормализации запросов."""

import pytest

from halal_ai.utils.query_expander import expand_query, normalize_food_query


class TestQueryExpander:
    """Тесты для расширения запросов синонимами."""

    def test_expand_query_with_known_term(self):
        """Проверяет расширение запроса с известным термином."""
        query = "Можно ли есть свинину?"
        variants = expand_query(query)
        
        assert len(variants) > 1
        assert query in variants  # Оригинал всегда присутствует
        assert any("мясо свиньи" in v.lower() for v in variants)

    def test_expand_query_with_namaz(self):
        """Проверяет расширение запроса о намазе."""
        query = "Расскажи про намаз"
        variants = expand_query(query)
        
        assert any("молитва" in v.lower() for v in variants)
        assert any("салят" in v.lower() or "салат" in v.lower() for v in variants)

    def test_expand_query_no_synonyms(self):
        """Проверяет что запрос без известных терминов не расширяется."""
        query = "Что такое Коран?"
        variants = expand_query(query)
        
        assert len(variants) == 1
        assert variants[0] == query

    def test_expand_query_limits_variants(self):
        """Проверяет что количество вариантов ограничено."""
        query = "свинина намаз пост"  # Несколько терминов
        variants = expand_query(query)
        
        assert len(variants) <= 5  # Максимум 5 вариантов


class TestNormalizeFoodQuery:
    """Тесты для нормализации запросов о еде."""

    def test_normalize_svinina_to_myaso_svini(self):
        """Проверяет замену 'свинина' на 'мясо свиньи'."""
        query = "Можно ли есть свинину?"
        normalized = normalize_food_query(query)
        
        assert "свинин" not in normalized.lower()
        assert "мясо свиньи" in normalized.lower()

    def test_normalize_adds_context_for_prohibition(self):
        """Проверяет добавление контекстных слов для запретов."""
        query = "Можно ли есть свинину?"
        normalized = normalize_food_query(query)
        
        assert "запрет" in normalized.lower() or "харам" in normalized.lower()

    def test_normalize_handles_different_forms(self):
        """Проверяет обработку разных форм слова 'свинина'."""
        queries = [
            "свинина",
            "свинину",
            "свининой",
            "свинины",
        ]
        
        for query in queries:
            normalized = normalize_food_query(query)
            assert "мясо свиньи" in normalized.lower()
            assert "свинин" not in normalized.lower()

    def test_normalize_preserves_other_content(self):
        """Проверяет что другой контент запроса сохраняется."""
        query = "В Коране есть запрет на свинину?"
        normalized = normalize_food_query(query)
        
        assert "коран" in normalized.lower()
        assert "запрет" in normalized.lower()
        assert "мясо свиньи" in normalized.lower()

    def test_normalize_no_changes_for_other_queries(self):
        """Проверяет что не связанные с едой запросы не меняются."""
        query = "Расскажи о намазе"
        normalized = normalize_food_query(query)
        
        assert normalized.lower() == query.lower()
