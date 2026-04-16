"""FastAPI application for HalalAI RAG Service"""

import logging
import json
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException, Depends

from halal_rag.rag.retriever import SimpleRAG
from . import dependencies
from .models import ChatRequest, ChatResponse
from .services import ChatService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown"""
    logger.info("Starting HalalAI RAG API...")

    # Startup: Initialize RAG
    try:
        logger.info("Loading RAG system...")
        data_file = Path(__file__).parent.parent.parent.parent / "data" / "quran_ru.jsonl"

        if not data_file.exists():
            raise FileNotFoundError(f"Quran data not found at {data_file}")

        docs = []
        with open(data_file, 'r', encoding='utf-8') as f:
            for line in f:
                docs.append(json.loads(line))

        logger.info(f"Loaded {len(docs)} Quranic verses")
        rag = SimpleRAG(documents=docs, use_finetuned=True)
        dependencies.set_rag(rag)
        logger.info("✓ RAG system ready")

    except Exception as e:
        logger.error(f"Failed to initialize RAG: {e}")
        raise

    logger.info("✓ Application startup complete")
    yield

    # Shutdown
    logger.info("Shutting down RAG system...")


app = FastAPI(
    title="HalalAI RAG API",
    description="Semantic search and QA system for Quranic questions",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/llm/health", tags=["Health"])
async def health_check():
    """Check service availability"""
    rag = dependencies.get_rag()
    llm_client = dependencies.get_llm_client()

    return {
        "status": "ok",
        "rag_ready": "ready" if rag else "initializing",
        "llm_ready": "ready" if llm_client else "not initialized"
    }


@app.post("/llm/chat", response_model=ChatResponse, tags=["Chat"])
async def chat(request: ChatRequest):
    """Main chat endpoint for Q&A"""
    if not request.messages:
        raise HTTPException(status_code=400, detail="Messages cannot be empty")

    # Get dependencies
    rag = dependencies.get_rag()
    llm_client = dependencies.get_llm_client()

    if not rag:
        raise HTTPException(status_code=503, detail="RAG system not initialized")

    # Process chat
    service = ChatService(rag=rag, llm_client=llm_client)
    return await service.process_chat(request)


@app.get("/llm/info", tags=["Docs"])
async def api_info():
    """Get API information"""
    return {
        "name": "HalalAI RAG API",
        "version": "1.0.0",
        "description": "LLM service with RAG integration for Quranic questions",
        "endpoints": {
            "health": "/llm/health",
            "chat": "/llm/chat (POST)",
            "info": "/llm/info",
            "docs": "/docs"
        }
    }


@app.get("/", tags=["Docs"], include_in_schema=False)
async def root():
    """Redirect to API info"""
    return {
        "message": "See /llm/info for API documentation",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host="localhost",
        port=8001,
        log_level="info"
    )
