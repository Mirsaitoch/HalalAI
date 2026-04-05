
import httpx
import logging
from typing import Optional

logger = logging.getLogger(__name__)

class OpenRouterClient:

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "openrouter/auto",
        base_url: str = "https://openrouter.ai/api/v1"
    ):
        import os

        self.api_key = api_key or os.getenv("OPEN_ROUTER_KEY")
        if not self.api_key:
            raise ValueError(
                "OPEN_ROUTER_KEY environment variable not set. "
                "Get your key from https://openrouter.ai"
            )

        self.model = model
        self.base_url = base_url
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "HTTP-Referer": "https://halalai.app",
                "X-Title": "HalalAI"
            }
        )

    async def generate(
        self,
        query: str,
        sources: str,
        system_prompt: Optional[str] = None,
        max_tokens: int = 1000,
        temperature: float = 0.7,
        model: Optional[str] = None
    ) -> str:
        if not system_prompt:
            system_prompt = """You are HalalAI, an expert Islamic assistant based on the Quran.
Your role is to answer questions accurately using the provided Quranic verses.
Provide clear, respectful answers grounded in Islamic teachings.
Always cite the specific Surah and Ayah numbers.
Respond in Russian."""

        prompt = f"""Question: {query}

Relevant Quranic Verses:
{sources}

Based on these Quranic verses, provide a clear and accurate answer to the question."""

        try:
            effective_model = model if model else self.model
            logger.info(f"Using model: {effective_model}")

            response = await self.client.post(
                "/chat/completions",
                json={
                    "model": effective_model,
                    "messages": [
                        {
                            "role": "system",
                            "content": system_prompt
                        },
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    "temperature": temperature,
                    "max_tokens": max_tokens,
                }
            )

            response.raise_for_status()
            data = response.json()

            answer = data["choices"][0]["message"]["content"]
            logger.info(
                f"OpenRouter response: "
                f"{len(answer)} chars, "
                f"tokens: {data['usage']['total_tokens']}"
            )

            return answer

        except httpx.HTTPError as e:
            logger.error(f"OpenRouter API error: {e}")
            raise
        except KeyError as e:
            logger.error(f"Unexpected OpenRouter response format: {e}")
            raise ValueError(f"Invalid OpenRouter response: {e}")

    async def close(self):
        await self.client.aclose()

    def __del__(self):
        try:
            import asyncio
            asyncio.run(self.close())
        except:
            pass

class MockOpenRouterClient:

    async def generate(
        self,
        query: str,
        sources: str,
        **kwargs
    ) -> str:
        return f"Based on the Quranic verses provided, the answer to your question '{query}' is derived from Islamic teachings. The relevant verses show that..."
