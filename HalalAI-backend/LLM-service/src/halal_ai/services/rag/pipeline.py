"""RAG Pipeline для работы с векторным поиском."""

import logging
from typing import Any, Dict, List, Optional

from sentence_transformers import SentenceTransformer

from halal_ai.services.rag.store import SimpleVectorStore

logger = logging.getLogger(__name__)


class RAGPipeline:
    """Высокоуровневый пайплайн для добавления и поиска контекста."""

    def __init__(
        self,
        embedding_model_name: str,
        store_path: str,
        device: str = "cpu",
    ):
        """
        Инициализирует RAG pipeline.
        
        Args:
            embedding_model_name: Название модели для эмбеддингов
            store_path: Путь к файлу векторного хранилища
            device: Устройство для модели эмбеддингов (cpu, cuda, mps)
        """
        self.embedding_model_name = embedding_model_name
        self.device = device
        self.embedder = SentenceTransformer(embedding_model_name, device=device)
        self.store = SimpleVectorStore(store_path)
        self.store.load()
        logger.info(
            "Инициализирован RAG pipeline (модель эмбеддингов=%s, документов=%s).",
            embedding_model_name,
            self.store.document_count,
        )

    @property
    def document_count(self) -> int:
        """Возвращает количество документов в хранилище."""
        return self.store.document_count

    def add_texts(self, docs: List[Dict[str, Any]]) -> int:
        """
        Добавляет документы в индекс.
        
        Args:
            docs: Список документов с полями id, text, metadata
            
        Returns:
            Количество добавленных документов
        """
        if not docs:
            return 0
        
        texts = [doc["text"] for doc in docs]
        embeddings = self.embedder.encode(
            texts,
            convert_to_tensor=True,
            normalize_embeddings=True,
        )
        return self.store.add_documents(docs, embeddings)

    def rebuild(self, docs: List[Dict[str, Any]]) -> int:
        """
        Полностью пересоздаёт индекс, очищая его перед добавлением новых документов.
        
        Args:
            docs: Список документов для индексации
            
        Returns:
            Количество добавленных документов
        """
        self.store.reset()
        return self.add_texts(docs)

    def retrieve(
        self,
        query: str,
        top_k: int = 3,
        filters: Optional[Dict[str, Any]] = None,
        search_top_k: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Ищет релевантные документы для запроса.
        
        Args:
            query: Поисковый запрос
            top_k: Количество документов для возврата
            filters: Фильтры по метаданным
            search_top_k: Максимальное количество для поиска перед фильтрацией
            
        Returns:
            Список найденных документов с метаданными и score
        """
        if not query.strip():
            return []

        embedding = self.embedder.encode(
            [query],
            convert_to_tensor=True,
            normalize_embeddings=True,
        )

        limit = max(top_k, search_top_k or top_k)
        results = self.store.similarity_search(embedding, top_k=limit, filters=filters)
        
        if not results and filters:
            logger.info("Фильтр RAG не дал результатов, пробуем без ограничений.")
            results = self.store.similarity_search(embedding, top_k=limit)

        return results[:top_k]
