#!/usr/bin/env python3
"""
Интерактивный скрипт для поиска в Коране с использованием RAG.
Позволяет вводить вопросы и получать релевантные аяты.

Использование:
  python interactive_search.py              # Fine-tuned XLM-RoBERТa (Quranic)
  python interactive_search.py --jina       # Jina Embeddings v5 (retrieval)
  python interactive_search.py --sbert      # SBERT Large NLU RU (базовая)
  python interactive_search.py --sbert-ft   # SBERT Fine-tuned (Quranic) ⭐
  python interactive_search.py --help       # Справка
"""

import json
import sys
from pathlib import Path
from halal_rag.rag.retriever import SimpleRAG


def load_quran_data():
    """Загружает данные Корана из quran_ru.jsonl."""
    data_file = Path(__file__).parent / "data" / "quran_ru.jsonl"

    if not data_file.exists():
        raise FileNotFoundError(f"Файл Корана не найден: {data_file}")

    docs = []
    with open(data_file, 'r', encoding='utf-8') as f:
        for line in f:
            docs.append(json.loads(line))

    print(f"✓ Загружено {len(docs)} аятов Корана\n")
    return docs


def show_help():
    """Показывает справку по использованию."""
    print(__doc__)
    sys.exit(0)


def display_results(results):
    """Красивый вывод результатов поиска."""
    if not results:
        print("❌ Результатов не найдено\n")
        return

    print(f"📖 Найдено {len(results)} результатов:\n")

    for i, result in enumerate(results, 1):
        sura = result.get('sura', '?')
        verse = result.get('verse', '?')
        text = result.get('text', '')
        score = result.get('score', 'N/A')

        print(f"{i}. Сура {sura}:{verse}")
        print(f"   📝 {text}")
        print(f"   ⭐ Score: {score:.4f}" if isinstance(score, float) else "")
        print()


def main():
    """Главная функция интерактивного поиска."""
    # Парсим аргументы
    use_jina = "--jina" in sys.argv
    use_sbert = "--sbert" in sys.argv and "--sbert-ft" not in sys.argv
    use_sbert_ft = "--sbert-ft" in sys.argv
    if "--help" in sys.argv or "-h" in sys.argv:
        show_help()

    print("=" * 70)
    print("🕌 HalalAI Quranic Search - Интерактивный поиск по Корану")
    print("=" * 70)

    # Определяем какую модель использовать
    if use_jina:
        model_name = "jinaai/jina-embeddings-v5-text-small-retrieval"
        use_finetuned = False
        model_label = "Jina Embeddings v5 (small, retrieval)"
    elif use_sbert_ft:
        model_name = "ai-forever/sbert_large_nlu_ru"
        use_finetuned = True
        model_label = "Fine-tuned SBERT Large NLU RU ⭐ (Quranic)"
    elif use_sbert:
        model_name = "ai-forever/sbert_large_nlu_ru"
        use_finetuned = False
        model_label = "SBERT Large NLU RU (базовая, русский)"
    else:
        model_name = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
        use_finetuned = True
        model_label = "Fine-tuned XLM-RoBERТa (Quranic)"

    print(f"📦 Модель: {model_label}")
    print("=" * 70)
    print("Команды:")
    print("  - Введите вопрос для поиска")
    print("  - 'quit' или 'exit' для выхода")
    print("  - 'help' для справки")
    print("  - 'model' для информации о модели")
    print("=" * 70)
    print()

    # Загружаем данные и инициализируем RAG
    print("⏳ Инициализация RAG системы...")
    try:
        docs = load_quran_data()

        rag = SimpleRAG(
            documents=docs,
            embedding_model=model_name,
            use_finetuned=use_finetuned
        )
        print("✅ RAG система готова\n")
    except Exception as e:
        print(f"❌ Ошибка инициализации: {e}")
        import traceback
        traceback.print_exc()
        return

    # Интерактивный цикл
    while True:
        try:
            query = input("🔍 Введите вопрос: ").strip()

            if not query:
                continue

            if query.lower() in ['quit', 'exit']:
                print("\n👋 До свидания!")
                break

            if query.lower() == 'help':
                print("\n📚 Примеры вопросов:")
                print("  - молитва")
                print("  - милосердие")
                print("  - справедливость")
                print("  - мудрость")
                print("  - запретная еда")
                print()
                continue

            if query.lower() == 'model':
                print(f"\n📊 Информация о модели:")
                print(f"  Name: {model_name}")
                print(f"  Fine-tuned: {'Yes' if use_finetuned else 'No'}")
                print(f"  Embedding dim: {rag.embeddings.embedding_dim}")
                print()
                continue

            # Поиск в RAG
            print()
            results = rag.search(query, top_k=5)
            display_results(results)

        except KeyboardInterrupt:
            print("\n\n👋 До свидания!")
            break
        except Exception as e:
            print(f"❌ Ошибка поиска: {e}\n")


if __name__ == "__main__":
    main()
