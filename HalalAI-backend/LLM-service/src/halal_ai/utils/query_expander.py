"""Расширение и нормализация запросов для улучшения RAG поиска."""

import re
from typing import List


# Словарь синонимов для исламских терминов (ключи - корни слов)
QUERY_SYNONYMS = {
    "свинин": ["мясо свиньи", "свиное мясо", "свинья"],
    "намаз": ["молитва", "салят", "салат"],
    "пост": ["ураза", "рамадан", "саум"],
    "закят": ["милостын", "подаян"],
    "хадж": ["паломничеств", "мекк"],
    "харам": ["запрещен", "запретн", "грех"],
    "халяль": ["дозволен", "разреш", "позвол"],
}


def generate_query_variants(query: str) -> List[str]:
    """
    Генерирует множественные варианты запроса для улучшения RAG поиска.
    
    Комбинирует нормализацию и расширение синонимами.
    
    Args:
        query: Оригинальный запрос пользователя
        
    Returns:
        Список вариантов запроса (от наиболее до наименее релевантных)
    """
    variants = []
    
    # 1. Нормализованный запрос (самый важный)
    normalized = normalize_food_query(query)
    variants.append(normalized)
    
    # 2. Варианты с синонимами
    expanded = expand_query(query)
    for variant in expanded:
        if variant not in variants:
            variants.append(variant)
    
    # 3. Оригинальный запрос (на случай если нормализация ухудшила)
    if query not in variants:
        variants.append(query)
    
    # Ограничиваем до 5 самых важных вариантов
    return variants[:5]


def expand_query(query: str) -> List[str]:
    """
    Расширяет запрос синонимами для улучшения поиска.
    
    Args:
        query: Оригинальный запрос пользователя
        
    Returns:
        Список вариантов запроса включая оригинал
    """
    query_lower = query.lower()
    variants = [query]  # Начинаем с оригинала
    
    # Ищем известные термины в запросе (с учетом разных форм слова)
    for term, synonyms in QUERY_SYNONYMS.items():
        # Ищем по корню слова (например "свинин" найдет "свинину", "свинины" и т.д.)
        # Используем [а-яёА-ЯЁ]* для кириллицы и убираем \b в конце
        term_pattern = rf'\b{re.escape(term)}[а-яёА-ЯЁ]*'
        if re.search(term_pattern, query_lower):
            # Создаем варианты с каждым синонимом
            for synonym in synonyms:
                # Заменяем термин на синоним
                variant = re.sub(
                    term_pattern,
                    synonym,
                    query_lower,
                    flags=re.IGNORECASE
                )
                if variant != query_lower and variant not in variants:
                    variants.append(variant)
    
    return variants[:5]  # Ограничиваем 5 вариантами


def normalize_food_query(query: str) -> str:
    """
    Нормализует запросы о еде для лучшего поиска в Коране.
    
    Args:
        query: Запрос пользователя
        
    Returns:
        Нормализованный запрос
    """
    query_lower = query.lower()
    
    # Заменяем "свинина" на "мясо свиньи" (как в Коране)
    if "свинин" in query_lower:
        query_lower = re.sub(r'\bсвинин\w*\b', 'мясо свиньи', query_lower)
    
    # Для вопросов о свинине добавляем ключевые слова из аятов
    if "свин" in query_lower:
        # Добавляем контекст из самих аятов о запрете
        keywords_to_add = []
        
        # Если это вопрос "что говорится", "можно ли" и т.д.
        if any(word in query_lower for word in ["что", "говор", "можно", "ли", "разрешен", "дозволен"]):
            # Добавляем ключевые слова из аятов о запрете свинины
            keywords_to_add.extend([
                "запрет", "запретил", "харам",
                "мертвечина", "кровь", "принесено жертву"
            ])
        
        if keywords_to_add:
            query_lower += " " + " ".join(keywords_to_add)
    
    return query_lower
