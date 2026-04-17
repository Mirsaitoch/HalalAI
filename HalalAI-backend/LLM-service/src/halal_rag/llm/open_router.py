
import httpx
import logging
from typing import Optional
from .interfaces import ILLMClient

logger = logging.getLogger(__name__)


class OpenRouterClient(ILLMClient):

    def __init__(
        self,
        api_key: str,
        model: str = "openrouter/auto",
        base_url: str = "https://openrouter.ai/api/v1"
    ):
        if not api_key:
            raise ValueError(
                "api_key must be provided. "
                "Get your key from https://openrouter.ai"
            )
        self.api_key = api_key
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
            system_prompt = """
            # Ты - HalalAI, опытный специалист по исламу.
            1. Задача - точно отвечать на вопросы, **основываясь на Коране и Хадисах**.
            2. Давать **четкие**, уважительные ответы, основанные на исламском учении.
            3. Всегда приводите конкретные номера сур и аятов.
            4. Отвечай на **русском** языке.
            """

        prompt = f"""
        # Вопрос : {query}
        Соответствующие аяты Корана:
        {sources}
        """

        try:
            effective_model = model if model else self.model
            logger.info(f"Используем llm-модель: {effective_model}")
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
