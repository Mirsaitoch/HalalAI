from abc import ABC, abstractmethod
from typing import Any
import torch


class IEmbeddingEncoder(ABC):
    """Interface for embedding dto"""

    @abstractmethod
    def encode(self, texts: list[str]) -> torch.Tensor:
        """Encode multiple texts to embeddings"""
        ...

    @abstractmethod
    def encode_single(self, text: str) -> torch.Tensor:
        """Encode single text to embedding"""
        ...


class IVectorSearcher(ABC):
    """Interface for vector search and storage"""

    @abstractmethod
    def add_documents(self, documents: list[dict[str, Any]], embeddings: torch.Tensor) -> None:
        """Add documents and their embeddings to the store"""
        ...

    @abstractmethod
    def search(self, query_embedding: torch.Tensor, top_k: int = 3) -> list[dict[str, Any]]:
        """Search for similar documents"""
        ...


class IRAGPipeline(ABC):
    """Interface for RAG pipeline"""

    @abstractmethod
    def search(self, query: str, top_k: int = 3) -> list[dict[str, Any]]:
        """Search for relevant documents based on query"""
        ...
