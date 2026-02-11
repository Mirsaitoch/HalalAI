"""Утилиты и вспомогательные функции."""

from .helpers import (
    build_rag_filters,
    chunk_text,
    extract_last_user_query,
    format_source_heading,
    serialize_sources,
)
from .query_expander import (
    expand_query,
    generate_query_variants,
    normalize_food_query,
)
from .surah_catalog import describe_surah, get_surah_info, get_surah_name, match_surah_numbers

__all__ = [
    # Helpers
    "build_rag_filters",
    "format_source_heading",
    "chunk_text",
    "extract_last_user_query",
    "serialize_sources",
    # Query expansion
    "expand_query",
    "generate_query_variants",
    "normalize_food_query",
    # Surah catalog
    "match_surah_numbers",
    "get_surah_info",
    "get_surah_name",
    "describe_surah",
]
