import argparse
import logging
import sys
from pathlib import Path
from typing import Any, Dict, List

import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

from config import DEFAULT_VECTOR_STORE_PATH, RAG_EMBEDDING_DEVICE, RAG_EMBEDDING_MODEL  # noqa: E402
from rag.surah_catalog import get_surah_name  # noqa: E402
from rag.simple_rag import RAGPipeline  # noqa: E402

logger = logging.getLogger(__name__)

DEFAULT_CSV_PATH = BASE_DIR / "sury.csv"


def _to_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        raise ValueError(f"Невозможно привести значение '{value}' к int")


def _clean_text(value: Any) -> str:
    return str(value).strip() if isinstance(value, str) else ""


def _validate_dataframe(df: pd.DataFrame) -> None:
    required = {"sura_index", "sura_title", "sura_subtitle", "verse_number", "text"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"В CSV нет обязательных колонок: {', '.join(sorted(missing))}")


def _build_documents(df: pd.DataFrame, window_size: int = 3) -> List[Dict[str, Any]]:
    window_size = max(1, window_size)
    half_window = max(0, window_size // 2)
    documents: List[Dict[str, Any]] = []

    for surah_value, group in df.groupby("sura_index"):
        surah_number = _to_int(surah_value)
        group = group.sort_values("verse_number")
        verses = group.to_dict("records")

        for idx, row in enumerate(verses):
            start = max(0, idx - half_window)
            end = min(len(verses), idx + half_window + 1)
            window_rows = verses[start:end]

            text_fragments = [_clean_text(item.get("text")) for item in window_rows]
            combined_text = " ".join([t for t in text_fragments if t]).strip()
            if not combined_text:
                continue

            verse_numbers: List[int] = []
            for item in window_rows:
                try:
                    verse_numbers.append(_to_int(item.get("verse_number")))
                except Exception:
                    continue
            if not verse_numbers:
                continue

            ayah_from = min(verse_numbers)
            ayah_to = max(verse_numbers)
            surah_name_ru = _clean_text(row.get("sura_title")) or get_surah_name(surah_number, prefer_locale="ru")
            surah_name_en = get_surah_name(surah_number, prefer_locale="en")
            surah_subtitle = _clean_text(row.get("sura_subtitle"))

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
                        "source": DEFAULT_CSV_PATH.name,
                    },
                }
            )

    logger.info("Сформировано %s документов для индекса.", len(documents))
    return documents


def ingest_sury(
    csv_path: Path = DEFAULT_CSV_PATH,
    store_path: Path = Path(DEFAULT_VECTOR_STORE_PATH),
    window_size: int = 3,
) -> int:
    csv_path = csv_path.expanduser().resolve()
    store_path = store_path.expanduser().resolve()

    if not csv_path.exists():
        raise FileNotFoundError(f"CSV-файл не найден: {csv_path}")

    logger.info("Загружаем данные из %s", csv_path)
    df = pd.read_csv(csv_path)
    _validate_dataframe(df)

    documents = _build_documents(df, window_size=window_size)
    if not documents:
        raise RuntimeError("Не удалось сформировать документы для индексации (возможно, пустой CSV).")

    pipeline = RAGPipeline(
        embedding_model_name=RAG_EMBEDDING_MODEL,
        store_path=str(store_path),
        device=RAG_EMBEDDING_DEVICE,
    )
    added = pipeline.rebuild(documents)
    logger.info("Индекс пересобран: добавлено %s документов. Храним в %s", added, store_path)
    return added


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Пересобрать RAG-индекс из sury.csv")
    parser.add_argument(
        "--csv",
        dest="csv_path",
        type=str,
        default=str(DEFAULT_CSV_PATH),
        help="Путь до sury.csv (по умолчанию – локальный файл в LLM-service)",
    )
    parser.add_argument(
        "--store",
        dest="store_path",
        type=str,
        default=str(DEFAULT_VECTOR_STORE_PATH),
        help="Путь до файла векторного индекса",
    )
    parser.add_argument(
        "--window",
        dest="window_size",
        type=int,
        default=3,
        help="Размер окна (число аятов вокруг текущего) для формирования документа",
    )
    return parser.parse_args()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    args = parse_args()
    ingest_sury(
        csv_path=Path(args.csv_path),
        store_path=Path(args.store_path),
        window_size=args.window_size,
    )

