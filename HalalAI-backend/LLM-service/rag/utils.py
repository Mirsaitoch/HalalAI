from typing import Any, Dict, List

from rag.surah_catalog import match_surah_numbers, describe_surah, get_surah_name


def build_rag_filters(query: str) -> Dict[str, Any]:
    filters: Dict[str, Any] = {}
    surah_numbers = match_surah_numbers(query)
    if surah_numbers:
        filters["surah"] = surah_numbers
    return filters


def format_source_heading(metadata: Dict[str, Any]) -> str:
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
    if ayah:
        parts.append(f"Аят {ayah}")

    heading = ", ".join(parts) if parts else metadata.get("title") or "Источник"

    tafsir_sources = metadata.get("tafsir_sources") or []
    if tafsir_sources:
        heading += f" ({', '.join(tafsir_sources)})"

    return heading

