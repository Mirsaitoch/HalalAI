"""FastAPI dependencies для dependency injection."""

from typing import Optional

from fastapi import HTTPException

from halal_ai.core.exceptions import ModelNotLoadedException, RAGNotInitializedException
from halal_ai.services.llm import LocalLLM
from halal_ai.services.rag import RAGPipeline

# Глобальные instance (будут инициализированы при старте)
_local_llm: Optional[LocalLLM] = None
_rag_pipeline: Optional[RAGPipeline] = None


def get_local_llm() -> LocalLLM:
    """
    Dependency для получения локальной LLM.
    
    Returns:
        Экземпляр LocalLLM
        
    Raises:
        HTTPException: Если модель не загружена
    """
    if _local_llm is None or _local_llm.model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return _local_llm


def get_rag_pipeline() -> Optional[RAGPipeline]:
    """
    Dependency для получения RAG pipeline.
    
    Returns:
        Экземпляр RAGPipeline или None если RAG отключен
    """
    return _rag_pipeline


def set_local_llm(llm: LocalLLM) -> None:
    """Устанавливает глобальный экземпляр LocalLLM."""
    global _local_llm
    _local_llm = llm


def set_rag_pipeline(pipeline: Optional[RAGPipeline]) -> None:
    """Устанавливает глобальный экземпляр RAGPipeline."""
    global _rag_pipeline
    _rag_pipeline = pipeline
