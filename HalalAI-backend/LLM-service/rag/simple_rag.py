import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

import torch
from sentence_transformers import SentenceTransformer
from torch import nn

def _normalize_value(value: Any):
    if isinstance(value, str) and value.isdigit():
        try:
            return int(value)
        except (ValueError, TypeError):
            return value
    return value

logger = logging.getLogger(__name__)


class SimpleVectorStore:
    """Минимальный векторный стор на Torch тензорах."""

    def __init__(self, storage_path: str):
        self.storage_path = Path(storage_path)
        self.documents: List[Dict[str, Any]] = []
        self.embeddings: Optional[torch.Tensor] = None
        self._loaded = False

    @property
    def document_count(self) -> int:
        return len(self.documents)

    def load(self) -> None:
        if not self.storage_path.exists():
            logger.info("Файл векторного индекса %s не найден, будет создан новый.", self.storage_path)
            self._loaded = True
            return

        payload = torch.load(self.storage_path, map_location="cpu")
        self.documents = payload.get("documents", [])
        tensor = payload.get("embeddings")
        if tensor is not None:
            self.embeddings = tensor.float()
        self._loaded = True
        logger.info("Загружено %s фрагментов векторного индекса.", len(self.documents))

    def save(self) -> None:
        if not self._loaded:
            return

        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "documents": self.documents,
            "embeddings": self.embeddings.detach().cpu() if self.embeddings is not None else None,
        }
        torch.save(payload, self.storage_path)

    def add_documents(self, docs: List[Dict[str, Any]], embeddings: torch.Tensor) -> int:
        if not docs:
            return 0

        embeddings = embeddings.detach().cpu()
        if self.embeddings is None:
            self.embeddings = embeddings
        else:
            self.embeddings = torch.cat([self.embeddings, embeddings], dim=0)

        self.documents.extend(docs)
        self.save()
        logger.info("Добавлено %s новых фрагментов в индекс (итого %s).", len(docs), len(self.documents))
        return len(docs)

    def similarity_search(
        self,
        query_embedding: torch.Tensor,
        top_k: int = 3,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        if self.embeddings is None or not self.documents:
            return []

        query = query_embedding.detach().cpu()
        if query.dim() == 1:
            query = query.unsqueeze(0)

        doc_embeddings = self.embeddings
        docs = self.documents

        if filters:
            candidate_indices: List[int] = []
            for idx, doc in enumerate(self.documents):
                metadata = doc.get("metadata") or {}
                if self._matches_filters(metadata, filters):
                    candidate_indices.append(idx)

            if not candidate_indices:
                return []

            index_tensor = torch.tensor(candidate_indices, dtype=torch.long)
            doc_embeddings = self.embeddings.index_select(0, index_tensor)
            docs = [self.documents[i] for i in candidate_indices]

        # Косинусное сходство
        doc_embeddings = nn.functional.normalize(doc_embeddings, p=2, dim=1)
        query = nn.functional.normalize(query, p=2, dim=1)

        scores = torch.matmul(doc_embeddings, query.T).squeeze(1)
        k = max(1, min(top_k, len(docs)))
        top_scores, indices = torch.topk(scores, k=k)

        results: List[Dict[str, Any]] = []
        for score, idx in zip(top_scores.tolist(), indices.tolist()):
            doc = docs[idx]
            results.append(
                {
                    "id": doc.get("id"),
                    "text": doc.get("text"),
                    "metadata": doc.get("metadata", {}) or {},
                    "score": float(score),
                }
            )
        return results

    @staticmethod
    def _matches_filters(metadata: Dict[str, Any], filters: Dict[str, Any]) -> bool:
        for key, expected in filters.items():
            actual = metadata.get(key)
            actual = _normalize_value(actual)

            if isinstance(expected, (list, tuple, set)):
                normalized = {_normalize_value(item) for item in expected}
                if actual not in normalized:
                    return False
            else:
                if _normalize_value(expected) != actual:
                    return False
        return True


class RAGPipeline:
    """Высокоуровневый пайплайн для добавления и поиска контекста."""

    def __init__(
        self,
        embedding_model_name: str,
        store_path: str,
        device: str = "cpu",
    ):
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
        return self.store.document_count

    def add_texts(self, docs: List[Dict[str, Any]]) -> int:
        if not docs:
            return 0
        texts = [doc["text"] for doc in docs]
        embeddings = self.embedder.encode(
            texts,
            convert_to_tensor=True,
            normalize_embeddings=True,
        )
        return self.store.add_documents(docs, embeddings)

    def retrieve(
        self,
        query: str,
        top_k: int = 3,
        filters: Optional[Dict[str, Any]] = None,
        search_top_k: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
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


