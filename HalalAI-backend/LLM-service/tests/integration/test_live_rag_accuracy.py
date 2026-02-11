"""
Тесты точности RAG на живом сервере.

ВАЖНО: Перед запуском этих тестов нужно запустить сервер:
    uvicorn halal_ai.main:app --host 0.0.0.0 --port 8000

Затем запустите тесты:
    pytest tests/integration/test_live_rag_accuracy.py -v
"""

import requests
import pytest


BASE_URL = "http://localhost:8000"


@pytest.fixture(scope="module")
def check_server_running():
    """Проверяет что сервер запущен."""
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code not in [200, 503]:
            pytest.skip("Сервер не запущен или недоступен")
    except requests.exceptions.ConnectionError:
        pytest.skip("Сервер не запущен. Запустите: uvicorn halal_ai.main:app --port 8000")


class TestLiveRAGAccuracy:
    """Тесты точности RAG на живом сервере."""

    def test_rag_status(self, check_server_running):
        """Проверяет статус RAG системы."""
        response = requests.get(f"{BASE_URL}/rag/status")
        assert response.status_code == 200
        
        data = response.json()
        assert data["enabled"] is True
        assert data["documents"] > 6000, f"Слишком мало документов: {data['documents']}"
        print(f"\n✅ RAG содержит {data['documents']} документов")

    def test_svinina_query_finds_correct_ayat(self, check_server_running):
        """Проверяет что запрос о свинине находит правильные аяты."""
        response = requests.post(
            f"{BASE_URL}/chat",
            json={"messages": [{"role": "user", "content": "Можно ли есть свинину?"}]},
            timeout=60,
        )
        
        assert response.status_code == 200, f"Ошибка: {response.text}"
        
        data = response.json()
        sources = data.get("sources", [])
        
        # Должны быть найдены источники
        assert len(sources) > 0, "RAG не вернул источники"
        
        # Хотя бы один из ожидаемых сур должен быть в результатах
        expected_surahs = [2, 5, 16]  # Аль-Бакара 173, Аль-Анам 145, Ан-Нахль 115
        found_surahs = [s["metadata"]["surah"] for s in sources]
        matching = set(found_surahs) & set(expected_surahs)
        
        print(f"\n📊 Найденные суры: {found_surahs}")
        print(f"✅ Совпадения с ожидаемыми: {list(matching)}")
        
        for i, source in enumerate(sources[:3], 1):
            print(f"  {i}. Сура {source['metadata']['surah']}, аяты {source['metadata']['ayah_range']} (score: {source['score']:.3f})")
        
        assert len(matching) > 0, (
            f"Не найдены ожидаемые суры. "
            f"Ожидалось: {expected_surahs}, "
            f"Найдено: {found_surahs}"
        )
        
        # Проверяем качество результатов (score должен быть разумным)
        best_score = sources[0]["score"]
        assert best_score > 0.5, f"Слишком низкий score: {best_score}"

    def test_svinina_normalization_works(self, check_server_running):
        """Проверяет что нормализация 'свинина' → 'мясо свиньи' улучшает поиск."""
        response = requests.post(
            f"{BASE_URL}/chat",
            json={"messages": [{"role": "user", "content": "Можно ли есть свинину?"}]},
            timeout=60,
        )
        
        assert response.status_code == 200
        sources = response.json()["sources"]
        
        if sources:
            first_surah = sources[0]["metadata"]["surah"]
            print(f"\n✅ Первый результат: Сура {first_surah}, аяты {sources[0]['metadata']['ayah_range']}")
            print(f"   Score: {sources[0]['score']:.3f}")
            
            assert first_surah in [2, 5, 16], (
                f"После нормализации первый результат должен быть из сур 2, 5 или 16. "
                f"Получено: сура {first_surah}"
            )

    @pytest.mark.parametrize(
        "query,expected_surah_in_top3",
        [
            ("Можно ли есть свинину?", [2, 5, 16]),
            ("Что говорится о мясе свиньи?", [2, 5, 16]),
            ("Свинина харам?", [2, 5, 16]),
        ],
    )
    def test_pork_queries_variations(self, check_server_running, query, expected_surah_in_top3):
        """Параметризованный тест для разных формулировок о свинине."""
        response = requests.post(
            f"{BASE_URL}/chat",
            json={"messages": [{"role": "user", "content": query}]},
            timeout=60,
        )
        
        assert response.status_code == 200
        sources = response.json()["sources"]
        found_surahs = [s["metadata"]["surah"] for s in sources[:3]]
        
        print(f"\n📝 Query: '{query}'")
        print(f"   Топ-3 суры: {found_surahs}")
        
        # Хотя бы одна из ожидаемых сур должна быть в топ-3
        assert any(s in expected_surah_in_top3 for s in found_surahs), (
            f"Query: '{query}' не нашел нужные суры. "
            f"Ожидалось хотя бы одна из {expected_surah_in_top3}, "
            f"Найдено: {found_surahs}"
        )

    def test_rag_score_ordering(self, check_server_running):
        """Проверяет что источники отсортированы по убыванию score."""
        response = requests.post(
            f"{BASE_URL}/chat",
            json={"messages": [{"role": "user", "content": "Что говорится о запретах в еде?"}]},
            timeout=60,
        )
        
        assert response.status_code == 200
        sources = response.json()["sources"]
        
        if len(sources) > 1:
            scores = [s["score"] for s in sources]
            print(f"\n📊 Scores: {[f'{s:.3f}' for s in scores[:5]]}")
            
            assert scores == sorted(scores, reverse=True), (
                "Источники должны быть отсортированы по убыванию score"
            )

    def test_rag_metadata_complete(self, check_server_running):
        """Проверяет что метаданные источников полные."""
        response = requests.post(
            f"{BASE_URL}/chat",
            json={"messages": [{"role": "user", "content": "Расскажи о свинине"}]},
            timeout=60,
        )
        
        assert response.status_code == 200
        sources = response.json()["sources"]
        assert len(sources) > 0
        
        # Проверяем первый источник
        source = sources[0]
        assert "id" in source
        assert "score" in source
        assert "metadata" in source
        
        metadata = source["metadata"]
        required_fields = ["surah", "surah_name_ru", "ayah_from", "ayah_to", "ayah_range"]
        for field in required_fields:
            assert field in metadata, f"Отсутствует поле: {field}"
        
        # Проверяем типы
        assert isinstance(metadata["surah"], int)
        assert isinstance(metadata["surah_name_ru"], str)
        assert isinstance(source["score"], float)
        assert 0 <= source["score"] <= 1
        
        print(f"\n✅ Метаданные полные для источника: {source['id']}")

    def test_multiple_queries_consistency(self, check_server_running):
        """Проверяет стабильность результатов."""
        query = "Что говорится о мясе свиньи?"
        
        # Делаем 2 запроса
        response1 = requests.post(
            f"{BASE_URL}/chat",
            json={"messages": [{"role": "user", "content": query}]},
            timeout=60,
        )
        response2 = requests.post(
            f"{BASE_URL}/chat",
            json={"messages": [{"role": "user", "content": query}]},
            timeout=60,
        )
        
        sources1 = response1.json()["sources"]
        sources2 = response2.json()["sources"]
        
        # Источники должны быть одинаковыми
        assert len(sources1) == len(sources2), "Разное количество источников"
        
        for s1, s2 in zip(sources1, sources2):
            assert s1["id"] == s2["id"], "Разные ID источников"
            assert abs(s1["score"] - s2["score"]) < 0.001, "Разные scores"
        
        print(f"\n✅ Результаты стабильные ({len(sources1)} источников)")


if __name__ == "__main__":
    print("=" * 80)
    print("Тесты точности RAG на живом сервере")
    print("=" * 80)
    print("\nПеред запуском убедитесь что сервер запущен:")
    print("  uvicorn halal_ai.main:app --host 0.0.0.0 --port 8000")
    print("\nЗатем запустите тесты:")
    print("  pytest tests/integration/test_live_rag_accuracy.py -v -s")
    print("=" * 80)
