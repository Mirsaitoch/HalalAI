"""FastAPI application for HalalAI RAG Service"""

import logging
import json
from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI, HTTPException
from halal_rag.rag.retriever import SimpleRAG
from halal_rag.api import dependencies
from halal_rag.api.dto import ChatRequest, ChatResponse, HealthResponse, ApiInfoResponse, RootResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown"""
    print("🚀 Starting HalalAI RAG API...")

    # Startup: Initialize RAG
    try:
        print("📚 Loading RAG system...")
        data_file = Path(__file__).parent.parent.parent.parent / "data" / "quran_ru.jsonl"

        if not data_file.exists():
            raise FileNotFoundError(f"Quran data not found at {data_file}")

        docs = []
        with open(data_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line:
                    docs.append(json.loads(line))

        print(f"✓ Loaded {len(docs)} Quranic verses")
        rag = SimpleRAG(documents=docs, model_type="paraphrase", use_finetuned=False)
        dependencies.set_rag(rag)
        print("✓ RAG system ready")

    except Exception as e:
        print(f"❌ Failed to initialize RAG: {e}")
        raise

    print("✓ Application startup complete")
    yield

    # Shutdown
    print("👋 Shutting down RAG system...")


app = FastAPI(
    title="HalalAI RAG API",
    description="Semantic search and QA system for Quranic questions",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/llm/health", response_model=HealthResponse, tags=["Health"])
async def health_check() -> HealthResponse:
    """Check service availability"""
    rag = dependencies.get_rag()
    llm_client = dependencies.get_llm_client()

    return HealthResponse(
        status="ok",
        rag_ready="ready" if rag else "initializing",
        llm_ready="ready" if llm_client else "not initialized"
    )


@app.post("/llm/chat", response_model=ChatResponse, tags=["Chat"])
async def chat(request: ChatRequest):
    """Main chat endpoint for Q&A"""
    if not request.messages:
        raise HTTPException(status_code=400, detail="Messages cannot be empty")

    service = dependencies.get_chat_service()
    if not service:
        raise HTTPException(status_code=503, detail="Chat service not initialized")

    return await service.process_chat(request)


@app.get("/llm/info", response_model=ApiInfoResponse, tags=["Docs"])
async def api_info() -> ApiInfoResponse:
    """Get API information"""
    return ApiInfoResponse(
        name="HalalAI RAG API",
        version="1.0.0",
        description="LLM service with RAG integration for Quranic questions",
        endpoints={
            "health": "/llm/health",
            "chat": "/llm/chat (POST)",
            "info": "/llm/info",
            "docs": "/docs"
        }
    )


@app.get("/", response_model=RootResponse, tags=["Docs"], include_in_schema=False)
async def root() -> RootResponse:
    """Redirect to API info"""
    return RootResponse(
        message="See /llm/info for API documentation",
        docs="/docs"
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host="localhost",
        port=8001,
        log_level="info"
    )
