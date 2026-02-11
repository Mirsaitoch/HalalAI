#!/usr/bin/env python3
"""Скрипт для индексации данных из CSV в RAG."""

import argparse
import logging
import sys
from pathlib import Path

# Добавляем src в путь
src_path = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(src_path))

from halal_ai.core import BASE_DIR, rag_config
from halal_ai.services.rag import RAGPipeline, ingest_from_csv

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

DEFAULT_CSV_PATH = BASE_DIR / "sury.csv"


def parse_args() -> argparse.Namespace:
    """Парсит аргументы командной строки."""
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
        default=str(rag_config.VECTOR_STORE_PATH),
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


def main():
    """Основная функция."""
    args = parse_args()
    
    logger.info("=" * 80)
    logger.info("Запуск индексации Корана в RAG")
    logger.info("=" * 80)
    logger.info("CSV файл: %s", args.csv_path)
    logger.info("Векторное хранилище: %s", args.store_path)
    logger.info("Размер окна: %s аятов", args.window_size)
    logger.info("Модель эмбеддингов: %s", rag_config.EMBEDDING_MODEL)
    logger.info("Устройство: %s", rag_config.EMBEDDING_DEVICE)
    logger.info("-" * 80)
    
    try:
        # Создаем RAG pipeline
        logger.info("Инициализация RAG pipeline...")
        pipeline = RAGPipeline(
            embedding_model_name=rag_config.EMBEDDING_MODEL,
            store_path=args.store_path,
            device=rag_config.EMBEDDING_DEVICE,
        )
        logger.info("✅ RAG pipeline инициализирован")
        
        # Индексируем данные
        logger.info("Начинаем индексацию данных из CSV...")
        added = ingest_from_csv(
            csv_path=Path(args.csv_path),
            pipeline=pipeline,
            window_size=args.window_size,
        )
        
        logger.info("=" * 80)
        logger.info("✅ Индексация завершена успешно!")
        logger.info("Проиндексировано документов: %s", added)
        logger.info("Всего документов в индексе: %s", pipeline.document_count)
        logger.info("Векторное хранилище: %s", args.store_path)
        logger.info("=" * 80)
        
    except FileNotFoundError as exc:
        logger.error("❌ Файл не найден: %s", exc)
        sys.exit(1)
    except Exception as exc:
        logger.error("❌ Ошибка при индексации: %s", exc, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
