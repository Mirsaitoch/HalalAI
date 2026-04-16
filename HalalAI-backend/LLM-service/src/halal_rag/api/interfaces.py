"""Service interfaces for API layer"""

from abc import ABC, abstractmethod
from .models import ChatRequest, ChatResponse


class IChatService(ABC):
    """Interface for chat service"""

    @abstractmethod
    async def process_chat(self, request: ChatRequest) -> ChatResponse:
        """Process chat request end-to-end"""
        pass
