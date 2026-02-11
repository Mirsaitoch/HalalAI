"""Вспомогательные функции."""

import re
from typing import Any, Dict, List

from halal_ai.utils.surah_catalog import describe_surah, get_surah_name


def build_rag_filters(query: str) -> Dict[str, Any]:
    """Создает фильтры для RAG на основе запроса."""
    from halal_ai.utils.surah_catalog import match_surah_numbers

    filters: Dict[str, Any] = {}
    surah_numbers = match_surah_numbers(query)
    if surah_numbers:
        filters["surah"] = surah_numbers
    return filters


def format_source_heading(metadata: Dict[str, Any]) -> str:
    """Форматирует заголовок источника для отображения."""
    metadata = metadata or {}
    surah_num = metadata.get("surah")
    surah_name = (
        metadata.get("surah_name_ru")
        or metadata.get("surah_name_en")
        or (get_surah_name(surah_num, prefer_locale="ru") if surah_num else None)
        or (get_surah_name(surah_num, prefer_locale="en") if surah_num else None)
        or (describe_surah(surah_num) if surah_num else None)
    )

    parts: List[str] = []
    if surah_name:
        parts.append(surah_name)
    elif surah_num:
        parts.append(f"Сура {surah_num}")

    ayah = metadata.get("ayah_index")
    ayah_from = metadata.get("ayah_from")
    ayah_to = metadata.get("ayah_to")
    ayah_range = metadata.get("ayah_range")

    def _fmt(value):
        return int(value) if isinstance(value, str) and value.isdigit() else value

    if ayah_range:
        parts.append(f"Аяты {ayah_range}")
    elif ayah_from is not None and ayah_to is not None and ayah_from != ayah_to:
        parts.append(f"Аяты {_fmt(ayah_from)}–{_fmt(ayah_to)}")
    elif ayah_from is not None:
        parts.append(f"Аят {_fmt(ayah_from)}")
    elif ayah:
        parts.append(f"Аят {_fmt(ayah)}")

    heading = ", ".join(parts) if parts else metadata.get("title") or "Источник"

    tafsir_sources = metadata.get("tafsir_sources") or []
    if tafsir_sources:
        heading += f" ({', '.join(tafsir_sources)})"

    return heading


def chunk_text(text: str, chunk_size: int, chunk_overlap: int) -> List[str]:
    """Нарезает текст на перекрывающиеся фрагменты."""
    normalized = re.sub(r"\s+", " ", (text or "")).strip()
    if not normalized:
        return []
    if len(normalized) <= chunk_size:
        return [normalized]

    chunks: List[str] = []
    start = 0
    while start < len(normalized):
        end = min(start + chunk_size, len(normalized))
        chunk = normalized[start:end].strip()
        if chunk:
            chunks.append(chunk)
        if end == len(normalized):
            break
        start = max(0, end - chunk_overlap)
    return chunks


def extract_last_user_query(messages: List[Dict[str, str]]) -> str:
    """Извлекает последний вопрос пользователя из истории."""
    for message in reversed(messages):
        if message.get("role") == "user":
            return (message.get("content") or "").strip()
    return ""


def serialize_sources(sources: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Подготавливает список источников для ответа."""
    serialized: List[Dict[str, Any]] = []
    for src in sources:
        serialized.append(
            {
                "id": src.get("id"),
                "score": round(float(src.get("score", 0.0)), 4),
                "metadata": src.get("metadata") or {},
            }
        )
    return serialized
