"""Dependency Injection for FastAPI"""

import logging
from typing import Optional

from fastapi import Depends
from halal_rag.llm.open_router import OpenRouterClient
from halal_rag.rag.retriever import SimpleRAG

logger = logging.getLogger(__name__)

# Shared state (initialized once)
_rag: Optional[SimpleRAG] = None
_llm_client: Optional[OpenRouterClient] = None


def set_rag(rag: SimpleRAG) -> None:
    """Set RAG instance (called during app startup)"""
    global _rag
    _rag = rag


def set_llm_client(client: OpenRouterClient) -> None:
    """Set LLM client instance"""
    global _llm_client
    _llm_client = client


def get_rag() -> Optional[SimpleRAG]:
    """Get RAG instance"""
    return _rag


def get_llm_client() -> Optional[OpenRouterClient]:
    """Get or create LLM client (lazy initialization)"""
    global _llm_client
    if _llm_client is None:
        try:
            _llm_client = OpenRouterClient()
            logger.info("✓ OpenRouter client initialized")
        except Exception as e:
            logger.error(f"Failed to initialize OpenRouter client: {e}")
            _llm_client = None
    return _llm_client
