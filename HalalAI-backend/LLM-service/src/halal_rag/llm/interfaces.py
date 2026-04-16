from __future__ import annotations
from abc import ABC, abstractmethod


class ILLMClient(ABC):
    """Interface for LLM clients"""

    @abstractmethod
    async def generate(
        self,
        query: str,
        sources: str,
        system_prompt: str | None = None,
        max_tokens: int = 1000,
        temperature: float = 0.7,
        model: str | None = None
    ) -> str:
        """Generate response using LLM"""
        pass
