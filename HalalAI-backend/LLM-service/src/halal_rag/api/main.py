
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import logging
from contextlib import asynccontextmanager
from halal_rag.quality.checker import QualityChecker
from halal_rag.llm.open_router import OpenRouterClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global rag, quality_checker, _rag_initialized

    logger.info("Starting HalalAI RAG API...")

    quality_checker = QualityChecker()
    logger.info("✓ Quality checker ready")

    try:
        logger.info("Loading RAG system...")
        import json
        from pathlib import Path
        from halal_rag.rag.retriever import SimpleRAG

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
quality_checker = None
llm_client = None
_rag_initialized = False

def get_rag():
    return rag

def get_llm_client():
    global llm_client
    if llm_client is None:
        try:
            llm_client = OpenRouterClient()
            logger.info("✓ Open Router client initialized lazily")
        except Exception as e:
            logger.error(f"Failed to initialize OpenRouter client: {e}")
    return llm_client

class SearchRequest(BaseModel):
    query: str
    top_k: int = 5

class SearchResult(BaseModel):
    sura: int
    verse: int
    text: str
    title: str
    subtitle: str
    score: float

class SearchResponse(BaseModel):
    results: list[SearchResult]

class QARequest(BaseModel):
    query: str
    use_llm: bool = True
    top_k: int = 3
    model: str = "qwen/qwen3.6-plus:free"

class QAResponse(BaseModel):
    query: str
    sources: list[SearchResult]
    answer: str | None = None
    quality_assessment: dict | None = None


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "ok",
        "rag_ready": "ready" if _rag_initialized and rag else "initializing",
        "llm_ready": "ready" if llm_client else "not initialized"
    }

@app.post("/search", response_model=SearchResponse, tags=["RAG"])
async def search(request: SearchRequest):
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    logger.info(f"Searching for: {request.query}")

    rag_system = get_rag()
    if not rag_system:
        raise HTTPException(status_code=503, detail="RAG system initialization failed")

    results = rag_system.search(request.query, top_k=request.top_k)

    return SearchResponse(
        results=[
            SearchResult(
                sura=r['sura'],
                verse=r['verse'],
                text=r['text'],
                title=r.get('title', ''),
                subtitle=r.get('subtitle', ''),
                score=r['score']
            )
            for r in results
        ]
    )

@app.post("/qa", response_model=QAResponse, tags=["RAG"])
async def qa(request: QARequest):
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    logger.info(f"QA Query: {request.query} (use_llm={request.use_llm})")

    rag_system = get_rag()
    if not rag_system:
        raise HTTPException(status_code=503, detail="RAG system initialization failed")

    sources_raw = rag_system.search(request.query, top_k=request.top_k)
    sources = [
        SearchResult(
            sura=r['sura'],
            verse=r['verse'],
            text=r['text'],
            title=r.get('title', ''),
            subtitle=r.get('subtitle', ''),
            score=r['score']
        )
        for r in sources_raw
    ]

    answer = None
    quality_assessment = None

    if request.use_llm:
        try:
            client = get_llm_client()
            if client:
                sources_text = "\n\n".join(
                    [f"Сура {s.sura}:{s.verse}\n{s.text}" for s in sources]
                )

                answer = await client.generate(
                    query=request.query,
                    sources=sources_text,
                    model=request.model
                )
                logger.info(f"LLM generated answer ({len(answer)} chars)")

                if quality_checker and answer:
                    quality_assessment = quality_checker.check_response(
                        answer,
                        [s.dict() for s in sources]
                    )
                    logger.info(f"Quality: {quality_assessment.get('quality')}")

        except Exception as e:
            logger.error(f"LLM generation failed: {e}")

    return QAResponse(
        query=request.query,
        sources=sources,
        answer=answer,
        quality_assessment=quality_assessment
    )

class ChatRequest(BaseModel):
    messages: list[dict[str, str]]
    max_tokens: int = 256
    api_key: str | None = None
    remote_model: str = "qwen/qwen3.6-plus:free"

class ChatResponse(BaseModel):
    reply: str
    model: str | None = None
    used_remote: bool = False
    remote_error: str | None = None

@app.post("/chat", response_model=ChatResponse, tags=["Chat"])
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

    rag_system = get_rag()
    sources_raw = rag_system.search(last_user_msg, top_k=3) if rag_system else []
    sources_text = "\n\n".join(
        [f"Сура {r['sura']}:{r['verse']}\n{r['text']}" for r in sources_raw]
    ) if sources_raw else "No sources found"

    reply = ""
    model_used = request.remote_model
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
        model=model_used,
        used_remote=used_remote,
        remote_error=remote_error
    )

@app.get("/models", tags=["Config"])
async def get_models():
    return {
        "default_model": "qwen/qwen3.6-plus:free",
        "allowed_models": [
            "meta-llama/llama-3.3-70b-instruct:free",
            "mistralai/mistral-small-3.1-24b-instruct:free",
            "google/gemma-3-27b-it:free",
            "google/gemma-4-26b-a4b-it",
            "qwen/qwen3.6-plus:free"
        ]
    }

@app.get("/", tags=["Docs"])
async def root():
    return {
        "name": "HalalAI RAG API",
        "version": "1.0.0",
        "description": "Semantic search and QA system for Quranic questions",
        "endpoints": {
            "health": "/health",
            "search": "/search (POST)",
            "qa": "/qa (POST)",
            "docs": "/docs"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="localhost",
        port=8001,
        log_level="info"
    )
