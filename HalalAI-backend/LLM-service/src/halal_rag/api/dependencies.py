"""Dependency Injection for FastAPI"""

import logging
import os
from typing import Optional

from halal_rag.llm.interfaces import ILLMClient
from halal_rag.llm.open_router import OpenRouterClient
from halal_rag.rag.interfaces import IRAGPipeline
from halal_rag.rag.retriever import SimpleRAG
from .interfaces import IChatService

logger = logging.getLogger(__name__)


class DependencyContainer:
    """Manages dependencies for the application"""

    _rag: Optional[IRAGPipeline] = None
    _llm_client: Optional[ILLMClient] = None
    _chat_service: Optional[IChatService] = None

    @classmethod
    def set_rag(cls, rag: IRAGPipeline) -> None:
        """Set RAG instance (called during app startup)"""
        cls._rag = rag

    @classmethod
    def set_llm_client(cls, client: ILLMClient) -> None:
        """Set LLM client instance"""
        cls._llm_client = client

    @classmethod
    def get_rag(cls) -> Optional[IRAGPipeline]:
        """Get RAG instance"""
        return cls._rag

    @classmethod
    def get_llm_client(cls, api_key: Optional[str] = None) -> Optional[ILLMClient]:
        """Get or create LLM client (lazy initialization)"""
        if cls._llm_client is None:
            try:
                key = api_key or os.getenv("OPEN_ROUTER_KEY")
                if not key:
                    raise ValueError("OPEN_ROUTER_KEY must be provided or set as environment variable")
                cls._llm_client = OpenRouterClient()
                print("✓ OpenRouter client initialized")
            except Exception as e:
                print(f"⚠️  Failed to initialize OpenRouter client: {e}")
                cls._llm_client = None
        return cls._llm_client

    @classmethod
    def get_chat_service(cls) -> Optional[IChatService]:
        """Get or create ChatService singleton"""
        if cls._chat_service is None:
            rag = cls.get_rag()
            llm_client = cls.get_llm_client()
            if rag:
                from .services import ChatService
                cls._chat_service = ChatService(rag=rag, llm_client=llm_client)
                print("✓ ChatService initialized")
        return cls._chat_service


# Module-level convenience functions for backward compatibility
def set_rag(rag: IRAGPipeline) -> None:
    """Set RAG instance (called during app startup)"""
    DependencyContainer.set_rag(rag)
    # Reset chat service when RAG changes
    DependencyContainer._chat_service = None


def set_llm_client(client: ILLMClient) -> None:
    """Set LLM client instance"""
    DependencyContainer.set_llm_client(client)
    # Reset chat service when LLM client changes
    DependencyContainer._chat_service = None


def get_rag() -> Optional[IRAGPipeline]:
    """Get RAG instance"""
    return DependencyContainer.get_rag()


def get_llm_client(api_key: Optional[str] = None) -> Optional[ILLMClient]:
    """Get or create LLM client (lazy initialization)"""
    return DependencyContainer.get_llm_client(api_key=api_key)


def get_chat_service() -> Optional[IChatService]:
    """Get ChatService singleton"""
    return DependencyContainer.get_chat_service()
