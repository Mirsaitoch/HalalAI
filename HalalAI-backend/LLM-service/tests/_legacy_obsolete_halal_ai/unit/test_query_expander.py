"""Тесты для расширения и нормализации запросов."""

import pytest

from halal_ai.utils.query_expander import (
    decompose_complex_query,
    expand_query,
    generate_query_variants,
    get_context_keywords,
    get_query_category,
    get_rag_relevance_keywords,
    normalize_food_query,
)


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
        query = "Расскажи об истории Пророка"  # Нет известных терминов в словаре
        variants = expand_query(query)
        
        assert len(variants) == 1
        assert variants[0] == query
    
    def test_expand_query_with_quran(self):
        """Проверяет что запрос о Коране теперь расширяется (улучшение)."""
        query = "Что такое Коран?"
        variants = expand_query(query)
        
        # Теперь Коран в словаре и расширяется
        assert len(variants) > 1
        assert any("писание" in v.lower() or "قرآن" in v for v in variants)

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
    
    def test_normalize_alcohol_query(self):
        """Проверяет нормализацию запросов об алкоголе."""
        query = "Можно ли пить алкоголь?"
        normalized = normalize_food_query(query)
        
        assert "хамр" in normalized.lower() or "запрет" in normalized.lower()


class TestQueryCategory:
    """Тесты для определения категории запроса."""
    
    def test_food_category(self):
        """Проверяет определение категории 'food'."""
        queries = [
            "Можно ли есть свинину?",
            "Можно ли есть мясо?",
            "Алкоголь запрещен?"  # Слово "алкоголь" точно найдется
        ]
        
        for query in queries:
            category = get_query_category(query)
            assert category == "food", f"Query '{query}' expected 'food', got '{category}'"
    
    def test_prayer_category(self):
        """Проверяет определение категории 'prayer'."""
        queries = [
            "Как совершать намаз?",
            "Что такое дуа?",
            "Время намаза"  # Более явный вопрос о молитве
        ]
        
        for query in queries:
            category = get_query_category(query)
            assert category == "prayer", f"Query '{query}' expected 'prayer', got '{category}'"
    
    def test_law_category(self):
        """Проверяет определение категории 'law'."""
        queries = ["Это халяль или харам?", "Что дозволено?", "Запрещено ли это?"]
        
        for query in queries:
            category = get_query_category(query)
            assert category == "law"
    
    def test_general_category(self):
        """Проверяет определение категории 'general' для неизвестных запросов."""
        query = "Расскажи об истории Пророка"
        category = get_query_category(query)
        
        assert category == "general"


class TestQueryDecomposition:
    """Тесты для разбиения сложных запросов."""
    
    def test_decompose_simple_query(self):
        """Проверяет что простой запрос не разбивается."""
        query = "Что говорится о свинине?"
        decomposed = decompose_complex_query(query)
        
        assert len(decomposed) == 1
        assert decomposed[0] == query
    
    def test_decompose_complex_query(self):
        """Проверяет разбиение сложного запроса с 'и'."""
        query = "Что говорится о свинине и алкоголе?"
        decomposed = decompose_complex_query(query)
        
        # Должен создать два подвопроса
        assert len(decomposed) == 2
        assert "свинин" in decomposed[0].lower()
        assert "алкогол" in decomposed[1].lower()


class TestContextKeywords:
    """Тесты для контекстных ключевых слов."""
    
    def test_food_context_keywords(self):
        """Проверяет контекстные слова для категории 'food'."""
        query = "Можно ли есть свинину?"
        keywords = get_context_keywords(query)
        
        # Должны быть ключевые слова о дозволенности/запрете
        food_keywords = ["дозволено", "запрещено", "халяль", "харам"]
        assert any(kw in keywords for kw in food_keywords)
    
    def test_no_duplicate_keywords(self):
        """Проверяет что не добавляются слова уже присутствующие в запросе."""
        query = "Свинина халяль или харам?"
        keywords = get_context_keywords(query)
        
        # "халяль" и "харам" уже в запросе, не должны добавляться снова
        assert "халяль" not in keywords
        assert "харам" not in keywords


class TestGenerateQueryVariants:
    """Тесты для генерации вариантов запроса."""
    
    def test_generate_variants_with_max_limit(self):
        """Проверяет что количество вариантов не превышает лимит."""
        query = "Что говорится о свинине?"
        variants = generate_query_variants(query, max_variants=3)
        
        assert len(variants) <= 3
    
    def test_generate_variants_includes_original(self):
        """Проверяет что оригинальный запрос включен в варианты."""
        query = "Расскажи об истории"
        variants = generate_query_variants(query)
        
        assert query in variants
    
    def test_generate_variants_deduplication(self):
        """Проверяет что нет дубликатов в вариантах."""
        query = "Можно ли есть свинину?"
        variants = generate_query_variants(query)
        
        # Все варианты должны быть уникальными
        assert len(variants) == len(set(variants))


class TestGetRagRelevanceKeywords:
    """Тесты для ключевых слов релевантности RAG."""

    def test_svinina_returns_pork_keywords(self):
        """Запрос о свинине возвращает ключи для поиска в чанках."""
        keywords = get_rag_relevance_keywords("Что говорится о свинине в Коране?")
        assert "свинин" in keywords
        assert "мясо свиньи" in keywords
        # Текст про свинину должен содержать хотя бы один из ключей
        chunk_about_pork = "мясо свиньи, которое (или которая) является скверной"
        assert any(kw in chunk_about_pork.lower() for kw in keywords)

    def test_irrelevant_chunk_does_not_match(self):
        """Чанк не про свинину не должен совпадать с ключами свинины."""
        keywords = get_rag_relevance_keywords("Что говорится о свинине?")
        chunk_hunting = "Не убивайте охотничью добычу, находясь в ихраме"
        assert not any(kw in chunk_hunting.lower() for kw in keywords)

    def test_empty_or_generic_returns_list(self):
        """Пустой или общий запрос возвращает список (может быть пустым)."""
        assert isinstance(get_rag_relevance_keywords(""), list)
        assert isinstance(get_rag_relevance_keywords("Привет"), list)
