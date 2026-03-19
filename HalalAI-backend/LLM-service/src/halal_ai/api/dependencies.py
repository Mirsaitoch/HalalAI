"""FastAPI dependencies для dependency injection."""

from typing import Optional

from halal_ai.services.rag import RAGPipeline

# Глобальный instance RAG (будет инициализирован при старте)
_rag_pipeline: Optional[RAGPipeline] = None


def get_rag_pipeline() -> Optional[RAGPipeline]:
    """
    Dependency для получения RAG pipeline.

    Returns:
        Экземпляр RAGPipeline или None если RAG отключен
    """
    return _rag_pipeline


def set_rag_pipeline(pipeline: Optional[RAGPipeline]) -> None:
    """Устанавливает глобальный экземпляр RAGPipeline."""
    global _rag_pipeline
    _rag_pipeline = pipeline
