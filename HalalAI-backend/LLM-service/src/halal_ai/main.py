"""Главный файл FastAPI приложения."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from halal_ai.api.dependencies import set_rag_pipeline
from halal_ai.api.middleware import RateLimitMiddleware, rate_limiter
from halal_ai.api.routes import chat_router, health_router, metrics_router, rag_router
from halal_ai.core import rag_config
from halal_ai.services.rag import RAGPipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Управление жизненным циклом приложения (startup/shutdown)."""
    if rag_config.ENABLED:
        logger.info("Инициализируем RAG pipeline...")
        try:
            rag_pipeline = RAGPipeline(
                embedding_model_name=rag_config.EMBEDDING_MODEL,
                store_path=rag_config.VECTOR_STORE_PATH,
                device=rag_config.EMBEDDING_DEVICE,
            )
            set_rag_pipeline(rag_pipeline)
            logger.info("✅ RAG pipeline успешно инициализирован")
        except Exception as rag_exc:
            logger.error("❌ Не удалось инициализировать RAG pipeline: %s", rag_exc)
            set_rag_pipeline(None)
    else:
        logger.info("RAG отключен (RAG_ENABLED=false)")
        set_rag_pipeline(None)

    yield

    logger.info("Завершение работы сервиса...")


app = FastAPI(
    title="HalalAI LLM Service",
    version="1.0.0",
    description="Исламский ассистент с RAG и удалённой LLM через OpenRouter",
    lifespan=lifespan,
)

app.add_middleware(
    RateLimitMiddleware,
    rate_limiter=rate_limiter,
    enabled=True,
)

app.include_router(health_router)
app.include_router(chat_router)
app.include_router(rag_router)
app.include_router(metrics_router)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
