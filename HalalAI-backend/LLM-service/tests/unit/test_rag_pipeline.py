"""Юнит-тесты для RAG pipeline и vector store."""

from pathlib import Path
from typing import Any, Dict, List

import pytest
import torch

from halal_ai.services.rag.pipeline import RAGPipeline
from halal_ai.services.rag.store import SimpleVectorStore


@pytest.fixture
def temp_store_path(tmp_path):
    """Создает временный путь для vector store."""
    return str(tmp_path / "test_vector_store.pt")


@pytest.fixture
def sample_documents() -> List[Dict[str, Any]]:
    """Создает тестовые документы."""
    return [
        {
            "id": "doc_1",
            "text": "Он запретил вам мертвечину, кровь, мясо свиньи",
            "metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173},
        },
        {
            "id": "doc_2",
            "text": "Намаз является одним из пяти столпов ислама",
            "metadata": {"surah": 17, "ayah_from": 78, "ayah_to": 78},
        },
        {
            "id": "doc_3",
            "text": "Закят — обязательная милостыня для мусульман",
            "metadata": {"surah": 2, "ayah_from": 43, "ayah_to": 43},
        },
    ]


class TestSimpleVectorStore:
    """Тесты для SimpleVectorStore."""

    def test_store_initialization(self, temp_store_path):
        """Проверяет инициализацию пустого store."""
        store = SimpleVectorStore(temp_store_path)
        assert store.document_count == 0
        assert store.embeddings is None

    def test_store_add_documents(self, temp_store_path, sample_documents):
        """Проверяет добавление документов."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        # Создаем фейковые эмбеддинги
        embeddings = torch.randn(len(sample_documents), 384)
        
        added = store.add_documents(sample_documents, embeddings)
        
        assert added == len(sample_documents)
        assert store.document_count == len(sample_documents)
        assert store.embeddings.shape == (len(sample_documents), 384)

    def test_store_save_and_load(self, temp_store_path, sample_documents):
        """Проверяет сохранение и загрузку store."""
        # Создаем и сохраняем
        store1 = SimpleVectorStore(temp_store_path)
        store1.load()
        embeddings = torch.randn(len(sample_documents), 384)
        store1.add_documents(sample_documents, embeddings)
        
        # Загружаем в новый store
        store2 = SimpleVectorStore(temp_store_path)
        store2.load()
        
        assert store2.document_count == len(sample_documents)
        assert store2.embeddings.shape == embeddings.shape
        assert torch.allclose(store2.embeddings, embeddings, atol=1e-6)

    def test_store_similarity_search(self, temp_store_path, sample_documents):
        """Проверяет поиск по similarity."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        # Добавляем документы с нормализованными эмбеддингами
        embeddings = torch.randn(len(sample_documents), 384)
        embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
        store.add_documents(sample_documents, embeddings)
        
        # Ищем по первому эмбеддингу
        query_embedding = embeddings[0:1]
        results = store.similarity_search(query_embedding, top_k=1)
        
        assert len(results) == 1
        assert results[0]["id"] == "doc_1"  # Должен найти первый документ
        assert results[0]["score"] > 0.99  # Почти идентичный

    def test_store_similarity_search_with_filters(self, temp_store_path, sample_documents):
        """Проверяет поиск с фильтрацией по метаданным."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        embeddings = torch.randn(len(sample_documents), 384)
        store.add_documents(sample_documents, embeddings)
        
        # Ищем только из суры 2
        query_embedding = embeddings[0:1]
        results = store.similarity_search(
            query_embedding,
            top_k=10,
            filters={"surah": 2},
        )
        
        # Должны быть найдены только документы из суры 2
        for result in results:
            assert result["metadata"]["surah"] == 2

    def test_store_reset(self, temp_store_path, sample_documents):
        """Проверяет очистку store."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        embeddings = torch.randn(len(sample_documents), 384)
        store.add_documents(sample_documents, embeddings)
        
        assert store.document_count > 0
        
        # Очищаем
        store.reset()
        
        assert store.document_count == 0
        assert store.embeddings is None

    def test_store_empty_search_returns_empty(self, temp_store_path):
        """Проверяет что поиск в пустом store возвращает пустой результат."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        query_embedding = torch.randn(1, 384)
        results = store.similarity_search(query_embedding, top_k=3)
        
        assert len(results) == 0


class TestRAGPipelineIntegration:
    """Интеграционные тесты для RAGPipeline."""

    @pytest.fixture
    def mock_pipeline(self, temp_store_path, sample_documents, monkeypatch):
        """Создает RAG pipeline с мокированным embedder."""
        # Мокируем SentenceTransformer
        class MockEmbedder:
            def __init__(self, *args, **kwargs):
                pass
            
            def encode(self, texts, **kwargs):
                # Возвращаем фейковые эмбеддинги
                if isinstance(texts, str):
                    texts = [texts]
                embeddings = torch.randn(len(texts), 384)
                if kwargs.get("normalize_embeddings"):
                    embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
                return embeddings
        
        # Патчим SentenceTransformer
        import halal_ai.services.rag.pipeline
        monkeypatch.setattr(
            halal_ai.services.rag.pipeline,
            "SentenceTransformer",
            MockEmbedder,
        )
        
        # Создаем pipeline
        pipeline = RAGPipeline(
            embedding_model_name="mock-model",
            store_path=temp_store_path,
            device="cpu",
        )
        
        # Добавляем тестовые документы
        pipeline.add_texts(sample_documents)
        
        return pipeline

    def test_pipeline_initialization(self, mock_pipeline):
        """Проверяет инициализацию pipeline."""
        assert mock_pipeline.document_count == 3
        assert mock_pipeline.embedder is not None
        assert mock_pipeline.store is not None

    def test_pipeline_retrieve(self, mock_pipeline):
        """Проверяет поиск через pipeline."""
        results = mock_pipeline.retrieve("мясо свиньи", top_k=2)
        
        assert len(results) <= 2
        for result in results:
            assert "id" in result
            assert "text" in result
            assert "metadata" in result
            assert "score" in result

    def test_pipeline_retrieve_with_filters(self, mock_pipeline):
        """Проверяет поиск с фильтрами."""
        results = mock_pipeline.retrieve(
            "запрет",
            top_k=10,
            filters={"surah": 2},
        )
        
        # Все результаты должны быть из суры 2
        for result in results:
            assert result["metadata"]["surah"] == 2

    def test_pipeline_rebuild(self, mock_pipeline):
        """Проверяет переиндексацию."""
        initial_count = mock_pipeline.document_count
        
        new_docs = [
            {
                "id": "new_doc",
                "text": "Новый документ",
                "metadata": {"surah": 1},
            }
        ]
        
        added = mock_pipeline.rebuild(new_docs)
        
        assert added == 1
        assert mock_pipeline.document_count == 1  # Старые удалены

    def test_pipeline_empty_query_returns_empty(self, mock_pipeline):
        """Проверяет что пустой запрос возвращает пустой результат."""
        results = mock_pipeline.retrieve("", top_k=3)
        assert len(results) == 0
        
        results = mock_pipeline.retrieve("   ", top_k=3)
        assert len(results) == 0


class TestRAGFilters:
    """Тесты для фильтрации RAG результатов."""

    def test_filter_by_single_surah(self, temp_store_path, sample_documents):
        """Проверяет фильтрацию по одной суре."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        embeddings = torch.randn(len(sample_documents), 384)
        store.add_documents(sample_documents, embeddings)
        
        query_embedding = torch.randn(1, 384)
        results = store.similarity_search(
            query_embedding,
            top_k=10,
            filters={"surah": 2},
        )
        
        # Только документы из суры 2
        surah_2_docs = [d for d in sample_documents if d["metadata"]["surah"] == 2]
        assert len(results) == len(surah_2_docs)

    def test_filter_by_multiple_surahs(self, temp_store_path, sample_documents):
        """Проверяет фильтрацию по нескольким сурам."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        embeddings = torch.randn(len(sample_documents), 384)
        store.add_documents(sample_documents, embeddings)
        
        query_embedding = torch.randn(1, 384)
        results = store.similarity_search(
            query_embedding,
            top_k=10,
            filters={"surah": [2, 17]},  # Суры 2 и 17
        )
        
        # Результаты только из сур 2 или 17
        for result in results:
            assert result["metadata"]["surah"] in [2, 17]

    def test_filter_no_matches_returns_empty(self, temp_store_path, sample_documents):
        """Проверяет что фильтр без совпадений возвращает пустой результат."""
        store = SimpleVectorStore(temp_store_path)
        store.load()
        
        embeddings = torch.randn(len(sample_documents), 384)
        store.add_documents(sample_documents, embeddings)
        
        query_embedding = torch.randn(1, 384)
        results = store.similarity_search(
            query_embedding,
            top_k=10,
            filters={"surah": 999},  # Несуществующая сура
        )
        
        assert len(results) == 0
