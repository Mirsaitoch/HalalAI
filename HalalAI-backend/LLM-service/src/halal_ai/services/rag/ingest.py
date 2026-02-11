"""Сервис для индексации документов в RAG."""

import logging
from pathlib import Path
from typing import Any, Dict, List

import pandas as pd

from halal_ai.services.rag.pipeline import RAGPipeline
from halal_ai.utils import get_surah_name

logger = logging.getLogger(__name__)


def validate_dataframe(df: pd.DataFrame) -> None:
    """
    Валидирует структуру DataFrame с Кораническими данными.
    
    Args:
        df: DataFrame для валидации
        
    Raises:
        ValueError: Если отсутствуют обязательные колонки
    """
    required = {"sura_index", "sura_title", "sura_subtitle", "verse_number", "text"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"В CSV нет обязательных колонок: {', '.join(sorted(missing))}")


def build_documents(df: pd.DataFrame, window_size: int = 3) -> List[Dict[str, Any]]:
    """
    Создает документы для индексации из DataFrame с аятами.
    
    Объединяет соседние аяты в окно для лучшего контекста.
    
    Args:
        df: DataFrame с аятами
        window_size: Размер окна (количество аятов вокруг текущего)
        
    Returns:
        Список документов для индексации
    """
    window_size = max(1, window_size)
    half_window = max(0, window_size // 2)
    documents: List[Dict[str, Any]] = []

    for surah_value, group in df.groupby("sura_index"):
        surah_number = int(surah_value)
        group = group.sort_values("verse_number")
        verses = group.to_dict("records")

        for idx, row in enumerate(verses):
            start = max(0, idx - half_window)
            end = min(len(verses), idx + half_window + 1)
            window_rows = verses[start:end]

            text_fragments = [str(item.get("text", "")).strip() for item in window_rows]
            combined_text = " ".join([t for t in text_fragments if t]).strip()
            if not combined_text:
                continue

            verse_numbers: List[int] = []
            for item in window_rows:
                try:
                    verse_numbers.append(int(item.get("verse_number")))
                except Exception:
                    continue
            if not verse_numbers:
                continue

            ayah_from = min(verse_numbers)
            ayah_to = max(verse_numbers)
            surah_name_ru = str(row.get("sura_title", "")).strip() or get_surah_name(
                surah_number, prefer_locale="ru"
            )
            surah_name_en = get_surah_name(surah_number, prefer_locale="en")
            surah_subtitle = str(row.get("sura_subtitle", "")).strip()

            documents.append(
                {
                    "id": f"surah_{surah_number}_ayah_{ayah_from}_{ayah_to}",
                    "text": combined_text,
                    "metadata": {
                        "surah": surah_number,
                        "surah_name_ru": surah_name_ru,
                        "surah_name_en": surah_name_en,
                        "surah_subtitle": surah_subtitle,
                        "ayah_from": ayah_from,
                        "ayah_to": ayah_to,
                        "ayah_range": f"{ayah_from}-{ayah_to}" if ayah_from != ayah_to else str(ayah_from),
                        "source": "quran_csv",
                    },
                }
            )

    logger.info("Сформировано %s документов для индекса.", len(documents))
    return documents


def ingest_from_csv(
    csv_path: Path,
    pipeline: RAGPipeline,
    window_size: int = 3,
) -> int:
    """
    Индексирует данные из CSV файла в RAG pipeline.
    
    Args:
        csv_path: Путь к CSV файлу
        pipeline: RAG pipeline для добавления документов
        window_size: Размер окна для группировки аятов
        
    Returns:
        Количество проиндексированных документов
        
    Raises:
        FileNotFoundError: Если файл не найден
        RuntimeError: Если не удалось сформировать документы
    """
    csv_path = csv_path.expanduser().resolve()

    if not csv_path.exists():
        raise FileNotFoundError(f"CSV-файл не найден: {csv_path}")

    logger.info("Загружаем данные из %s", csv_path)
    df = pd.read_csv(csv_path)
    validate_dataframe(df)

    documents = build_documents(df, window_size=window_size)
    if not documents:
        raise RuntimeError("Не удалось сформировать документы для индексации (возможно, пустой CSV).")

    added = pipeline.rebuild(documents)
    logger.info("Индекс пересобран: добавлено %s документов.", added)
    return added
