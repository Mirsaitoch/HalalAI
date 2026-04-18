"""Business logic services"""

import logging
from typing import Optional

from halal_rag.llm.interfaces import ILLMClient
from halal_rag.rag.interfaces import IRAGPipeline
from .interfaces import IChatService
from .models import ChatRequest, ChatResponse

logger = logging.getLogger(__name__)


class ChatService(IChatService):
    """Service for handling chat requests"""

    def __init__(self, rag: Optional[IRAGPipeline], llm_client: Optional[ILLMClient]):
        self.rag = rag
        self.llm_client = llm_client

    def extract_user_message(self, messages: list[dict[str, str]]) -> str:
        """Extract last user message from conversation history"""
        for msg in reversed(messages):
            if msg.get("role") == "user":
                return msg.get("content", "").strip()
        return ""

    def search_sources(self, query: str, top_k: int = 3) -> list[dict]:
        """Search for relevant Quranic verses"""
        if not self.rag or not query:
            return []
        return self.rag.search(query, top_k=top_k)

    def format_sources(self, sources: list[dict]) -> str:
        """Format sources for LLM prompt"""
        if not sources:
            return "No sources found"
        return "\n\n".join([f"Сура {r['sura']}:{r['verse']}\n{r['text']}" for r in sources])

    async def generate_response(
        self, query: str, sources: str, api_key: Optional[str], model: str, max_tokens: int, temperature: float = 0.7
    ) -> tuple[str, bool, Optional[str]]:
        """Generate response using LLM"""
        if not api_key or not self.llm_client:
            return "", False, None

        try:
            reply = await self.llm_client.generate(
                query=query,
                sources=sources,
                model=model,
                max_tokens=max_tokens,
                temperature=temperature
            )
            return reply, True, None
        except Exception as e:
            error_msg = str(e)
            logger.error(f"LLM generation failed: {error_msg}")
            return "", False, error_msg

    def handle_error(self, error: Optional[str]) -> str:
        """Generate user-friendly error message"""
        if not error:
            return "Извините, удаленная модель недоступна. Пожалуйста, проверьте ваш API ключ и попробуйте снова."

        if "429" in error or "Too Many Requests" in error:
            return "OpenRouter API вернул ошибку 429: слишком много запросов. Это может быть из-за лимита free модели или превышения rate limit. Пожалуйста, попробуйте позже."
        elif "401" in error or "Unauthorized" in error or "authentication" in error.lower():
            return "Ошибка аутентификации OpenRouter: ваш API ключ недействителен или истек. Проверьте настройки."
        else:
            return f"Ошибка при обращении к OpenRouter: {error}"

    def build_prompt(self, query: str, sources: str) -> tuple[str, str]:
        """Build system prompt and user prompt"""
        system_prompt = """
            # Ты - HalalAI, опытный специалист по исламу.
            1. Задача - точно отвечать на вопросы, **основываясь на Коране и Хадисах**.
            2. Давать **четкие**, уважительные ответы, основанные на исламском учении.
            3. Всегда приводите конкретные номера сур и аятов.
            4. Отвечай на **русском** языке.
            """
        user_prompt = f"""
        # Вопрос : {query}
        Соответствующие аяты Корана:
        {sources}
        """
        return system_prompt, user_prompt

    async def process_chat(self, request: ChatRequest) -> ChatResponse:
        """Process chat request end-to-end"""
        # 1. Extract message
        query = self.extract_user_message(request.messages)
        if not query:
            return ChatResponse(
                reply="No user message found",
                used_remote=False,
                remote_error="Invalid request"
            )

        logger.info(f"Chat query: {query} (model={request.remote_model}, dry_run={request.dry_run})")

        # 2. Search sources
        sources = self.search_sources(query)
        sources_text = self.format_sources(sources)

        # 3. Build prompt
        system_prompt, user_prompt = self.build_prompt(query, sources_text)
        full_prompt = f"[SYSTEM]\n{system_prompt}\n\n[USER]\n{user_prompt}"

        # 4. dry_run — вернуть промт без отправки в LLM
        if request.dry_run:
            return ChatResponse(
                reply="[dry_run] Промт собран, LLM не вызывался",
                used_remote=False,
                prompt=full_prompt
            )

        # 5. Generate response
        reply, used_remote, error = await self.generate_response(
            query=query,
            sources=sources_text,
            api_key=request.api_key,
            model=request.remote_model,
            max_tokens=request.max_tokens,
            temperature=request.temperature
        )

        # 6. Handle errors if needed
        if not reply:
            reply = self.handle_error(error)

        return ChatResponse(
            reply=reply,
            used_remote=used_remote,
            remote_error=error
        )
