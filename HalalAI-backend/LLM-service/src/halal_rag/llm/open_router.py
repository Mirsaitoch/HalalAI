
import httpx
import logging
from typing import Optional
from .interfaces import ILLMClient

logger = logging.getLogger(__name__)


class OpenRouterClient(ILLMClient):

    def __init__(
        self,
        model: str = "openrouter/auto",
        base_url: str = "https://openrouter.ai/api/v1"
    ):
        self.model = model
        self.base_url = base_url
        self.client = httpx.AsyncClient(base_url=self.base_url)

    async def generate(
        self,
        query: str,
        sources: str,
        api_key: str,
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
        """
        if sources:
            prompt += f"""
                Соответствующие аяты Корана:
                {sources}
            """

        try:
            effective_model = model if model else self.model
            print(f"🤖 Используем llm-модель: {effective_model}")

            print(f"=== SYSTEM PROMPT ===\n{system_prompt}")
            print(f"=== USER PROMPT ===\n{prompt}")

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
                },
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "HTTP-Referer": "https://halalai.app",
                    "X-Title": "HalalAI"
                }
            )

            response.raise_for_status()
            data = response.json()

            try:
                answer = data["choices"][0]["message"]["content"]
            except (KeyError, IndexError, TypeError) as e:
                print(f"❌ Unexpected OpenRouter response format: {e}")
                raise ValueError(f"Invalid OpenRouter response: {e}") from e

            usage = data.get("usage") or {}
            total_tokens = usage.get("total_tokens", "n/a")
            print(
                f"✅ OpenRouter response: "
                f"{len(answer)} chars, "
                f"tokens: {total_tokens}"
            )
            print(f"=== LLM RESPONSE ===\n{answer}")

            return answer

        except httpx.HTTPError as e:
            print(f"❌ OpenRouter API error: {e}")
            raise

    async def close(self):
        try:
            await self.client.aclose()
        except Exception as e:
            pass  # Ignore close errors
