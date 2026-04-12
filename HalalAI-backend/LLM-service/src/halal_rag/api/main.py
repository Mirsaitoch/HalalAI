import logging
import json
from contextlib import asynccontextmanager
from halal_rag.llm.open_router import OpenRouterClient
from halal_rag.rag.retriever import SimpleRAG
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global rag, _rag_initialized

    logger.info("Starting HalalAI RAG API...")

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
        logger.info("✓ RAG system ready")
        _rag_initialized = True
    except Exception as e:
        logger.error(f"Failed to initialize RAG: {e}")
        _rag_initialized = True

    logger.info("✓ Application startup complete")
    yield
    logger.info("Shutting down RAG system...")

app = FastAPI(
    title="HalalAI RAG API",
    description="Semantic search and QA system for Quranic questions",
    version="1.0.0",
    lifespan=lifespan
)

rag = None
llm_client = None
_rag_initialized = False

def get_llm_client():
    global llm_client
    if llm_client is None:
        try:
            llm_client = OpenRouterClient()
            logger.info("✓ Open Router client initialized lazily")
        except Exception as e:
            logger.error(f"Failed to initialize OpenRouter client: {e}")
    return llm_client

@app.get("/llm/health", tags=["Health"])
async def health_check():
    return {
        "status": "ok",
        "rag_ready": "ready" if _rag_initialized and rag else "initializing",
        "llm_ready": "ready" if llm_client else "not initialized"
    }

class ChatRequest(BaseModel):
    messages: list[dict[str, str]]
    max_tokens: int = 256
    api_key: str | None = None
    remote_model: str = "qwen/qwen3.6-plus:free"

class ChatResponse(BaseModel):
    reply: str
    used_remote: bool = False
    remote_error: str | None = None

@app.post("/llm/chat", response_model=ChatResponse, tags=["Chat"])
async def chat(request: ChatRequest):
    if not request.messages:
        raise HTTPException(status_code=400, detail="Messages cannot be empty")

    last_user_msg = None
    for msg in reversed(request.messages):
        if msg.get("role") == "user":
            last_user_msg = msg.get("content", "").strip()
            break

    if not last_user_msg:
        raise HTTPException(status_code=400, detail="No user message found")

    logger.info(f"Chat query: {last_user_msg} (model={request.remote_model})")

    sources_raw = rag.search(last_user_msg, top_k=3) if rag else []
    sources_text = "\n\n".join(
        [f"Сура {r['sura']}:{r['verse']}\n{r['text']}" for r in sources_raw]
    ) if sources_raw else "No sources found"

    reply = ""
    used_remote = False
    remote_error = None

    if request.api_key:
        try:
            client = get_llm_client()
            if client:
                reply = await client.generate(
                    query=last_user_msg,
                    sources=sources_text,
                    model=request.remote_model,
                    max_tokens=request.max_tokens
                )
                used_remote = True
                logger.info(f"Generated reply using remote model: {len(reply)} chars")
        except Exception as e:
            logger.error(f"Remote LLM generation failed: {e}")
            remote_error = str(e)
            used_remote = False

    if not reply:
        if remote_error:
            if "429" in remote_error or "Too Many Requests" in remote_error:
                reply = "OpenRouter API вернул ошибку 429: слишком много запросов. Это может быть из-за лимита free модели или превышения rate limit. Пожалуйста, попробуйте позже."
            elif "401" in remote_error or "Unauthorized" in remote_error or "authentication" in remote_error.lower():
                reply = "Ошибка аутентификации OpenRouter: ваш API ключ недействителен или истек. Проверьте настройки."
            else:
                reply = f"Ошибка при обращении к OpenRouter: {remote_error}"
        else:
            reply = "Извините, удаленная модель недоступна. Пожалуйста, проверьте ваш API ключ и попробуйте снова."

    return ChatResponse(
        reply=reply,
        used_remote=used_remote,
        remote_error=remote_error
    )

@app.get("/llm/info", tags=["Docs"])
async def api_info():
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
    """Redirect to /llm/info for API documentation."""
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
