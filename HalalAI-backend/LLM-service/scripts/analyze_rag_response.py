#!/usr/bin/env python3
"""
Скрипт для разбора ответов RAG: отправляет запрос в /chat и выводит ответ, источники и оценки.

Использование:
  python scripts/analyze_rag_response.py "Что говорится о свинине?"
  python scripts/analyze_rag_response.py   # интерактивный режим

Требует запущенный сервер (например ./scripts/start_server.sh).
"""

import sys
from pathlib import Path

# Чтобы импорт requests работал при запуске из корня LLM-service
if __name__ == "__main__" and (Path(__file__).resolve().parent.parent / "venv").exists():
    pass  # venv при активации даёт requests

import requests


def analyze_response(query: str, *, use_rag: bool = True, base_url: str = "http://localhost:8000") -> None:
    """
    Отправляет запрос в /chat и печатает ответ, источники и оценки релевантности.

    Нужен для отладки: смотреть, какие суры/аяты подтягивает RAG и с каким score.
    """
    print("=" * 70)
    print(f"📝 Запрос: {query}")
    print("=" * 70)

    response = requests.post(
        f"{base_url}/chat",
        json={
            "messages": [{"role": "user", "content": query}],
            "use_rag": use_rag,
            "rag_top_k": 5,
        },
        timeout=60,
    )

    if response.status_code != 200:
        print(f"❌ Ошибка: {response.status_code}")
        print(response.text)
        return

    data = response.json()

    print(f"\n💬 Ответ LLM:")
    print(f"   {data.get('reply', 'N/A')[:500]}...")
    print(f"\n🤖 Модель: {data.get('model', 'N/A')}")
    print(f"📊 Remote: {data.get('used_remote', False)}")

    sources = data.get("sources", [])
    print(f"\n📚 Источников: {len(sources)}")

    if sources:
        print("\n📖 Источники:\n")
        for idx, source in enumerate(sources, 1):
            metadata = source.get("metadata", {})
            score = source.get("score", 0)
            text_preview = (source.get("text") or "")[:150]
            surah = metadata.get("surah", "?")
            surah_name = metadata.get("surah_name_ru", "Unknown")
            ayah_from = metadata.get("ayah_from", "?")
            ayah_to = metadata.get("ayah_to", "?")
            print(f"  [{idx}] Сура {surah}: {surah_name}, аяты {ayah_from}-{ayah_to}")
            print(f"      ⭐ Score: {score:.4f}")
            print(f"      📝 {text_preview}...")
            print()
        avg = sum(s.get("score", 0) for s in sources) / len(sources)
        print(f"📊 Средний score: {avg:.4f}")
        if avg > 0.7:
            print("✅ Высокая релевантность")
        elif avg > 0.5:
            print("⚠️ Средняя релевантность")
        else:
            print("❌ Низкая релевантность")
    print("\n" + "=" * 70 + "\n")


def main() -> None:
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
        analyze_response(query)
        return
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║            Анализатор ответов RAG HalalAI                      ║")
    print("╚════════════════════════════════════════════════════════════════╝")
    print("\nВведите запрос (или quit для выхода).\n")
    while True:
        try:
            query = input("❓ Запрос: ").strip()
        except EOFError:
            break
        if query.lower() in ("quit", "exit", "q"):
            print("👋 До свидания!")
            break
        if not query:
            continue
        try:
            analyze_response(query)
        except requests.exceptions.ConnectionError:
            print("❌ Сервер недоступен. Запустите: ./scripts/start_server.sh")
            break
        except Exception as e:
            print(f"❌ Ошибка: {e}")
        print()


if __name__ == "__main__":
    main()
