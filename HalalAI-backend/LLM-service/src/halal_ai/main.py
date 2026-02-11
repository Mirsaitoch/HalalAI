"""Главный файл FastAPI приложения."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from halal_ai.api.dependencies import set_local_llm, set_rag_pipeline
from halal_ai.api.routes import chat_router, health_router, rag_router
from halal_ai.core import rag_config
from halal_ai.services.llm import LocalLLM
from halal_ai.services.rag import RAGPipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Управление жизненным циклом приложения (startup/shutdown)."""
    # Startup
    try:
        # Загружаем локальную LLM
        logger.info("Загружаем локальную LLM модель...")
        local_llm = LocalLLM()
        await local_llm.load()
        set_local_llm(local_llm)
        logger.info("✅ Локальная модель успешно загружена")

        # Инициализируем RAG если включен
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

    except Exception as exc:
        logger.error("❌ Ошибка при загрузке компонентов LLM сервиса: %s", exc)
        raise

    yield  # Приложение работает

    # Shutdown (если нужно что-то освободить)
    logger.info("Завершение работы сервиса...")


app = FastAPI(
    title="HalalAI LLM Service",
    version="1.0.0",
    description="Исламский ассистент с RAG и локальными/удаленными моделями",
    lifespan=lifespan,
)

# Регистрируем роуты
app.include_router(health_router)
app.include_router(chat_router)
app.include_router(rag_router)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
