#!/usr/bin/env python3
"""
Скрипт для детального анализа ответов RAG системы.
"""

import requests
import json
import sys
from typing import Dict, Any


def analyze_response(query: str) -> None:
    """Анализирует ответ RAG системы на запрос."""
    print("=" * 70)
    print(f"📝 Запрос: {query}")
    print("=" * 70)
    
    # Отправляем запрос
    response = requests.post(
        "http://localhost:8000/chat",
        json={"messages": [{"role": "user", "content": query}]},
        timeout=60
    )
    
    if response.status_code != 200:
        print(f"❌ Ошибка: {response.status_code}")
        print(response.text)
        return
    
    data = response.json()
    
    # Основная информация
    print(f"\n💬 Ответ LLM:")
    print(f"   {data.get('reply', 'N/A')}")
    
    print(f"\n🤖 Модель: {data.get('model', 'N/A')}")
    print(f"📊 Использован remote: {data.get('used_remote', False)}")
    
    # Анализ источников
    sources = data.get("sources", [])
    print(f"\n📚 Источников найдено: {len(sources)}")
    
    if sources:
        print("\n📖 Детальная информация по источникам:\n")
        
        for idx, source in enumerate(sources, 1):
            metadata = source.get("metadata", {})
            score = source.get("score", 0)
            text_preview = source.get("text", "")[:150]
            
            surah = metadata.get("surah", "?")
            surah_name = metadata.get("surah_name_ru", "Unknown")
            ayah_from = metadata.get("ayah_from", "?")
            ayah_to = metadata.get("ayah_to", "?")
            
            print(f"  [{idx}] Сура {surah}: {surah_name}")
            print(f"      📍 Аяты: {ayah_from}-{ayah_to}")
            print(f"      ⭐ Relevance score: {score:.4f}")
            print(f"      📝 Текст: {text_preview}...")
            print()
        
        # Топ-3 суры
        top_surahs = [s["metadata"]["surah"] for s in sources[:3]]
        print(f"🎯 Топ-3 суры: {top_surahs}")
        
        # Средний score
        avg_score = sum(s.get("score", 0) for s in sources) / len(sources)
        print(f"📊 Средний relevance score: {avg_score:.4f}")
        
        # Проверка релевантности
        if avg_score > 0.7:
            print("✅ Отличная релевантность!")
        elif avg_score > 0.5:
            print("⚠️  Средняя релевантность")
        else:
            print("❌ Низкая релевантность - возможно нужно улучшить запрос")
    
    print("\n" + "=" * 70 + "\n")


def main():
    """Главная функция."""
    if len(sys.argv) > 1:
        # Запрос из аргументов командной строки
        query = " ".join(sys.argv[1:])
        analyze_response(query)
    else:
        # Интерактивный режим
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║            Анализатор ответов RAG системы HalalAI             ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print("\nВведите запрос (или 'quit' для выхода):\n")
        
        while True:
            query = input("❓ Запрос: ").strip()
            
            if query.lower() in ['quit', 'exit', 'q']:
                print("👋 До свидания!")
                break
            
            if not query:
                continue
            
            try:
                analyze_response(query)
            except requests.exceptions.ConnectionError:
                print("❌ Не удалось подключиться к серверу.")
                print("   Убедитесь что сервер запущен: ./venv/bin/uvicorn halal_ai.main:app --port 8000")
                break
            except Exception as e:
                print(f"❌ Ошибка: {e}")
            
            print()


if __name__ == "__main__":
    main()
