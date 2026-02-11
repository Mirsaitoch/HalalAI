"""Сервисы для RAG (Retrieval-Augmented Generation)."""

from .ingest import build_documents, ingest_from_csv, validate_dataframe
from .pipeline import RAGPipeline
from .store import SimpleVectorStore

__all__ = [
    "RAGPipeline",
    "SimpleVectorStore",
    "ingest_from_csv",
    "build_documents",
    "validate_dataframe",
]
