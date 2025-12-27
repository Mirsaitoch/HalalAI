import asyncio
import logging
import re
from typing import Any, Dict, List, Optional
from uuid import uuid4

import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from config import (
    DEFAULT_RAG_TOP_K,
    DEFAULT_SYSTEM_PROMPT,
    DEFAULT_VECTOR_STORE_PATH,
    MAX_HISTORY_MESSAGES,
    MAX_HISTORY_TOKEN_LENGTH,
    MAX_NEW_TOKENS,
    MIN_NEW_TOKENS,
    RAG_EMBEDDING_MODEL,
    RAG_ENABLED,
    RAG_SEARCH_TOP_K,
    REMOTE_LLM_ALLOWED_MODELS,
    REMOTE_LLM_MODEL,
    REMOTE_LLM_BASE_URL,
    REQUEST_TIMEOUT_SECONDS,
)
from prompt_utils import sanitize_system_prompt_content
from rag import RAGPipeline
from rag.surah_catalog import describe_surah
from rag.utils import build_rag_filters, format_source_heading
from remote_llm import call_remote_llm, should_use_remote_llm
from services.local_llm import LocalLLM

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LLM Service", version="1.0.0")

rag_pipeline: Optional[RAGPipeline] = None
local_llm = LocalLLM()
ALLOWED_ROLES = {"system", "user", "assistant"}
HALAL_SAFETY_PROMPT = (
    "Строго следуй исламским нормам: свинина и всё, что связано с ней, всегда харам; "
    "не допускай формулировок, что свинина может быть халяль. "
    "Если вопрос про свинину — объясни, что это харам, ссылаясь на релевантные аяты. "
    "Не утверждай, что запреты могут быть нарушены, кроме случаев крайней необходимости, "
    "и всегда подчёркивай, что это исключение, а не разрешение."
)

# Ограничивает выполнение произвольной корутины по времени
async def _execute_with_timeout(coro, stage: str):
    try:
        return await asyncio.wait_for(coro, timeout=REQUEST_TIMEOUT_SECONDS)
    except asyncio.TimeoutError:
        logger.error("%s превысила лимит %s секунд.", stage, REQUEST_TIMEOUT_SECONDS)
        raise HTTPException(
            status_code=504,
            detail=f"{stage} timed out after {REQUEST_TIMEOUT_SECONDS} seconds",
        )

# Нормализует значение max_tokens, не выходя за допустимые рамки
def _sanitize_max_tokens(value: Optional[int]) -> int:
    if value is None:
        return MAX_NEW_TOKENS
    return max(MIN_NEW_TOKENS, min(value, MAX_NEW_TOKENS))

# Нормализует количество RAG-контекстов
def _sanitize_top_k(value: Optional[int]) -> int:
    if value is None:
        return DEFAULT_RAG_TOP_K
    return max(1, min(value, 10))

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    prompt: Optional[str] = None
    messages: Optional[List[ChatMessage]] = None
    max_tokens: Optional[int] = 1024
    use_rag: bool = True
    rag_top_k: Optional[int] = None
    api_key: Optional[str] = None
    remote_model: Optional[str] = None

class ChatResponse(BaseModel):
    reply: str
    sources: Optional[List[Dict[str, Any]]] = None
    model: Optional[str] = None
    used_remote: Optional[bool] = None
    remote_error: Optional[str] = None

class KnowledgeDocument(BaseModel):
    document_id: Optional[str] = None
    text: str
    metadata: Optional[Dict[str, Any]] = None

class KnowledgeIngestRequest(BaseModel):
    documents: List[KnowledgeDocument]
    chunk_size: int = 800
    chunk_overlap: int = 100

# Достаёт последний пользовательский вопрос из истории
def _extract_last_user_query(messages: List[Dict[str, str]]) -> str:
    for message in reversed(messages):
        if message.get("role") == "user":
            return (message.get("content") or "").strip()
    return ""

# Вставляет guardrail, чтобы зафиксировать нужные суры
def _inject_surah_guardrail(messages: List[Dict[str, str]], surah_numbers: List[int]):
    unique_numbers = sorted({num for num in surah_numbers if isinstance(num, int)})
    if not unique_numbers:
        return messages

    labels = [describe_surah(num) or f"Сура {num}" for num in unique_numbers]
    if len(unique_numbers) == 1:
        guard_text = (
            f"Вопрос относится исключительно к {labels[0]}. "
            "Никогда не упоминай другие номера сур и не придумывай фактов вне предоставленных источников."
        )
    else:
        joined = "; ".join(labels)
        guard_text = (
            f"Вопрос относится к следующим сурам: {joined}. "
            "Используй только эти номера и избегай упоминания любых других сур."
        )

    guard_message = {"role": "system", "content": guard_text}
    augmented = messages[:]
    insert_idx = 1 if augmented and augmented[0].get("role") == "system" else 0
    augmented.insert(insert_idx, guard_message)
    return augmented

# Добавляет контекст из RAG в начало истории
def _inject_rag_context(messages: List[Dict[str, str]], contexts: List[Dict[str, Any]]):
    if not contexts:
        return messages

    context_blocks = []
    for ctx in contexts:
        text = (ctx.get("text") or "").strip()
        if not text:
            continue
        metadata = ctx.get("metadata") or {}
        heading = format_source_heading(metadata)
        block = f"{heading}\n{text}"
        context_blocks.append(block)

    if not context_blocks:
        return messages

    rag_instruction = (
        "Ниже приведены выдержки из базы знаний HalalAI. Используй только указанные в них факты "
        "и не додумывай за пределами контекста. "
        "Если данных недостаточно для ответа, прямо скажи об этом и не придумывай. "
        "Когда ссылаешься на аяты, обязательно указывай их в формате (сура XX, аят YY). "
        "Свинина всегда харам, это можно упоминать только как запрет с ссылкой на аят; "
        "не формулируй свинину как халяль ни при каких обстоятельствах."
    )
    rag_message = {
        "role": "system",
        "content": f"{rag_instruction}\n\n" + "\n\n".join(context_blocks),
    }

    augmented = messages[:]
    insert_idx = 1 if augmented and augmented[0].get("role") == "system" else 0
    augmented.insert(insert_idx, rag_message)
    return augmented

# Сериализует источники для ответа
def _serialize_sources(sources: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Подготавливает список источников для ответа."""
    serialized: List[Dict[str, Any]] = []
    for src in sources:
        serialized.append(
            {
                "id": src.get("id"),
                "score": round(float(src.get("score", 0.0)), 4),
                "metadata": src.get("metadata") or {},
            }
        )
    return serialized

# Режет текст на куски для индексации
def _chunk_text(text: str, chunk_size: int, chunk_overlap: int) -> List[str]:
    """Нарезает текст на перекрывающиеся фрагменты."""
    normalized = re.sub(r"\s+", " ", (text or "")).strip()
    if not normalized:
        return []
    if len(normalized) <= chunk_size:
        return [normalized]

    chunks: List[str] = []
    start = 0
    while start < len(normalized):
        end = min(start + chunk_size, len(normalized))
        chunk = normalized[start:end].strip()
        if chunk:
            chunks.append(chunk)
        if end == len(normalized):
            break
        start = max(0, end - chunk_overlap)
    return chunks

# Логирует ответ модели
def _log_model_output(content: str, model_label: str):
    if not content:
        logger.info("Ответ модели [%s] пустой.", model_label)
        return
    logger.info("Ответ модели [%s]: %s символов.\n%s", model_label, len(content), content)

# Гарантирует наличие system-промпта и его санитизацию
def _ensure_system_prompt(messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Добавляет дефолтный системный промпт, если он отсутствует."""
    if not messages:
        return [{"role": "system", "content": DEFAULT_SYSTEM_PROMPT}]
    first_role = messages[0].get("role")
    if first_role != "system":
        logger.info("Системный промпт отсутствует, добавляем дефолтный (client-side history без system role).")
        return [{"role": "system", "content": DEFAULT_SYSTEM_PROMPT}] + messages
    original_content = messages[0].get("content", "")
    sanitized = sanitize_system_prompt_content(original_content)
    if sanitized != original_content:
        logger.info("Получен пользовательский system prompt, выполняем санитизацию.")
    messages[0]["content"] = sanitized
    return messages

# Ограничивает историю по количеству сообщений и токенов
def _limit_history_length(messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Ограничивает историю по количеству сообщений и длине в токенах."""
    tokenizer = local_llm.tokenizer
    if tokenizer is None or not messages:
        return messages

    system_message = messages[0] if messages[0].get("role") == "system" else None
    history = messages[1:] if system_message else messages[:]

    # Ограничиваем сначала по количеству сообщений
    if len(history) > MAX_HISTORY_MESSAGES:
        history = history[-MAX_HISTORY_MESSAGES:]

    if not history:
        return messages

    # Затем по количеству токенов (всегда оставляем последнее сообщение)
    trimmed_history = []
    token_budget = MAX_HISTORY_TOKEN_LENGTH
    token_used = 0

    for message in reversed(history):
        content = message.get("content", "")
        token_count = len(tokenizer.encode(content, add_special_tokens=False))

        if trimmed_history and token_used + token_count > token_budget:
            break

        trimmed_history.append(message)
        token_used += token_count

    if not trimmed_history:
        trimmed_history = history[-1:]
    else:
        trimmed_history.reverse()

    if system_message:
        return [system_message] + trimmed_history
    return trimmed_history


def _remote_skip_reason(api_key: Optional[str]) -> Optional[str]:
    """Возвращает причину, по которой remote LLM не будет вызвана."""
    if not api_key:
        return "api_key не передан"
    if not REMOTE_LLM_ENABLED:
        return "REMOTE_LLM_ENABLED=false"
    return None


def _select_remote_model(user_model: Optional[str]) -> str:
    """Выбирает удалённую модель с учётом разрешённого списка."""
    candidate = (user_model or "").strip() or REMOTE_LLM_MODEL
    # Убираем возможный префикс "remote:" или "local:" — некоторые клиенты могут прислать метку модели из ответа
    if candidate.startswith("remote:") or candidate.startswith("local:"):
        candidate = candidate.split(":", 1)[1].strip()
    # Если явно указали "none", считаем что модели нет
    if candidate.lower() == "none":
        raise HTTPException(status_code=400, detail="remote_model не задан")
    if REMOTE_LLM_ALLOWED_MODELS and candidate not in REMOTE_LLM_ALLOWED_MODELS:
        raise HTTPException(
            status_code=400,
            detail=(
                f"remote_model '{candidate}' не разрешен. "
                f"Доступные: {', '.join(REMOTE_LLM_ALLOWED_MODELS)}"
            ),
        )
    return candidate

# Нормализует входящие сообщения из запроса
def _prepare_messages(request: ChatRequest) -> List[Dict[str, str]]:
    """Нормализует и проверяет структуру сообщений из запроса."""
    normalized: List[Dict[str, str]] = []

    if request.messages:
        for msg in request.messages:
            role = (msg.role or "").strip().lower()
            if role not in ALLOWED_ROLES:
                raise HTTPException(status_code=400, detail=f"Unsupported role '{msg.role}'")
            content = (msg.content or "").strip()
            if not content:
                continue
            normalized.append({"role": role, "content": content})
    elif request.prompt:
        normalized.append({"role": "user", "content": request.prompt.strip()})
    else:
        raise HTTPException(status_code=400, detail="Either 'prompt' or 'messages' must be provided")

    if not normalized:
        raise HTTPException(status_code=400, detail="Message list is empty after normalization")

    with_system = _ensure_system_prompt(normalized)
    guarded = _inject_halal_guardrail(with_system)
    return _limit_history_length(guarded)

# Добавляет обязательный safety-блок о хараме свинины
def _inject_halal_guardrail(messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    if not messages:
        return [{"role": "system", "content": HALAL_SAFETY_PROMPT}]
    insert_idx = 1 if messages[0].get("role") == "system" else 0
    augmented = messages[:]
    augmented.insert(
        insert_idx,
        {"role": "system", "content": HALAL_SAFETY_PROMPT},
    )
    return augmented

# Инициализирует RAG-пайплайн, если включён
def _initialize_rag_pipeline():
    global rag_pipeline
    if not RAG_ENABLED:
        logger.info("RAG отключен (RAG_ENABLED=false) — пропускаем инициализацию.")
        return
    try:
        from config import DEFAULT_VECTOR_STORE_PATH, RAG_EMBEDDING_MODEL, RAG_EMBEDDING_DEVICE

        rag_pipeline = RAGPipeline(
            embedding_model_name=RAG_EMBEDDING_MODEL,
            store_path=DEFAULT_VECTOR_STORE_PATH,
            device=RAG_EMBEDDING_DEVICE,
        )
    except Exception as exc:
        rag_pipeline = None
        logger.error("Не удалось инициализировать RAG pipeline: %s", exc)

# Загружает локальную модель и индекс при старте сервиса
@app.on_event("startup")
async def startup_event():
    try:
        await local_llm.load()
        _initialize_rag_pipeline()
    except Exception as exc:
        logger.error("❌ Ошибка при загрузке компонентов LLM сервиса: %s", exc)
        raise

@app.get("/health")
async def health_check():
    """Проверка здоровья сервиса"""
    if local_llm.model is None or local_llm.tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "healthy", "model": local_llm.model_name}

# Обрабатывает запрос на генерацию ответа (основная точка входа)
@app.post("/chat", response_model=ChatResponse, response_model_exclude_none=False)
async def chat(request: ChatRequest):
    """Генерация ответа на основе промпта или истории сообщений"""
    try:
        return await _execute_with_timeout(_handle_chat_request(request), "LLM generation")
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Ошибка при генерации: %s", exc)
        raise HTTPException(status_code=500, detail=f"Generation error: {str(exc)}")


# Выполняет полноценный пайплайн генерации (подготовка, RAG, remote/local)
async def _handle_chat_request(request: ChatRequest) -> ChatResponse:
    logger.info(
        "Получен запрос: prompt_provided=%s, messages=%s",
        bool(request.prompt),
        len(request.messages) if request.messages else 0,
    )
    if local_llm.model is None or local_llm.tokenizer is None:
        logger.error("Модель не загружена!")
        raise HTTPException(status_code=503, detail="Model not loaded")

    try:
        messages = _prepare_messages(request)
        logger.info("Используется история из %s сообщений (после нормализации)", len(messages))

        rag_sources: List[Dict[str, Any]] = []
        remote_error: Optional[str] = None
        if request.use_rag:
            if not RAG_ENABLED:
                logger.info("RAG отключен через конфиг, пропускаем поиск контекста.")
            elif rag_pipeline is None:
                logger.info("RAG запрошен, но пайплайн не инициализирован.")
            elif rag_pipeline.document_count == 0:
                logger.info("RAG включен, но индекс пуст. Требуются данные для наполнения.")
            else:
                query_text = _extract_last_user_query(messages)
                if query_text:
                    rag_top_k = _sanitize_top_k(request.rag_top_k)
                    rag_filters = build_rag_filters(query_text)
                    if rag_filters:
                        logger.info("Попытка RAG с фильтрами: %s", rag_filters)
                        rag_sources = await asyncio.to_thread(
                            rag_pipeline.retrieve,
                            query_text,
                            top_k=rag_top_k,
                            filters=rag_filters or None,
                            search_top_k=RAG_SEARCH_TOP_K,
                        )
                        if not rag_sources:
                            logger.info("RAG: не найдено контекстов по фильтрам, пробуем без ограничений.")
                            rag_sources = await asyncio.to_thread(
                                rag_pipeline.retrieve,
                                query_text,
                                top_k=rag_top_k,
                                search_top_k=RAG_SEARCH_TOP_K,
                            )
                    else:
                        logger.info("RAG: фильтры не определены, выполняем поиск по всей базе.")
                        rag_sources = await asyncio.to_thread(
                            rag_pipeline.retrieve,
                            query_text,
                            top_k=rag_top_k,
                            search_top_k=RAG_SEARCH_TOP_K,
                        )

                    if rag_sources:
                        surah_numbers = [
                            ctx.get("metadata", {}).get("surah")
                            for ctx in rag_sources
                            if ctx.get("metadata", {}).get("surah") is not None
                        ]
                        if surah_numbers:
                            messages = _inject_surah_guardrail(messages, surah_numbers)
                        messages = _inject_rag_context(messages, rag_sources)
                        logger.info("Добавлено %s контекстов из RAG.", len(rag_sources))
                else:
                    logger.info("Не удалось определить пользовательский запрос для RAG.")

        max_new_tokens = _sanitize_max_tokens(request.max_tokens)

        if should_use_remote_llm(request.api_key):
            remote_model = _select_remote_model(request.remote_model)
            logger.info(
                "Используем удаленную LLM по пользовательскому ключу (model=%s, base_url=%s, max_tokens=%s).",
                remote_model,
                REMOTE_LLM_BASE_URL or "default",
                max_new_tokens,
            )
            try:
                content = await asyncio.to_thread(
                    call_remote_llm,
                    messages,
                    max_new_tokens,
                    request.api_key,  # type: ignore[arg-type]
                    remote_model,
                )
                _log_model_output(content, f"remote:{remote_model}")
                return ChatResponse(
                    reply=content,
                    sources=_serialize_sources(rag_sources) or None,
                    model=f"remote:{remote_model}",
                    used_remote=True,
                    remote_error="",
                )
            except Exception as remote_exc:
                logger.info(
                    "Удаленная LLM недоступна или вернула ошибку (%s). Переходим на локальную модель.",
                    remote_exc,
                )
                remote_error = str(remote_exc)
        else:
            reason = _remote_skip_reason(request.api_key)
            if reason:
                logger.info("Remote LLM пропущен: %s", reason)
        content = await asyncio.to_thread(local_llm.generate, messages, max_new_tokens)
        if not content:
            logger.info("Ответ локальной модели пустой.")
        _log_model_output(content, f"local:{local_llm.model_name}")
        return ChatResponse(
            reply=content,
            sources=_serialize_sources(rag_sources) or None,
            model=f"local:{local_llm.model_name}",
            used_remote=False,
            remote_error=remote_error or "",
        )

    except HTTPException:
        raise
    except RuntimeError as runtime_error:
        error_message = str(runtime_error).lower()
        if "out of memory" in error_message:
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
            logger.error("CUDA out of memory во время генерации: %s", runtime_error)
            raise HTTPException(status_code=500, detail="LLM ran out of memory during generation")
        logger.error("RuntimeError во время генерации: %s", runtime_error)
        raise HTTPException(status_code=500, detail=str(runtime_error))
    except Exception as exc:
        logger.error("Ошибка при генерации: %s", exc)
        raise HTTPException(status_code=500, detail=f"Generation error: {str(exc)}")

# Возвращает статус векторного индекса
@app.get("/rag/status")
async def rag_status():
    """Возвращает состояние векторного индекса."""
    return {
        "enabled": RAG_ENABLED,
        "documents": rag_pipeline.document_count if rag_pipeline else 0,
        "embedding_model": RAG_EMBEDDING_MODEL,
        "store_path": DEFAULT_VECTOR_STORE_PATH,
    }


@app.get("/models")
async def available_models():
    """Возвращает список доступных удалённых моделей и модель по умолчанию."""
    return {
        "default_model": REMOTE_LLM_MODEL,
        "allowed_models": REMOTE_LLM_ALLOWED_MODELS or [],
    }

# Добавляет новые документы в векторный индекс
@app.post("/rag/documents")
async def ingest_documents(payload: KnowledgeIngestRequest):
    """Добавляет новые документы в векторный индекс."""
    if not RAG_ENABLED:
        raise HTTPException(status_code=503, detail="RAG отключен через конфигурацию")
    if rag_pipeline is None:
        raise HTTPException(status_code=503, detail="RAG pipeline не инициализирован")

    chunk_size = max(200, min(payload.chunk_size, 2000))
    chunk_overlap = max(0, min(payload.chunk_overlap, chunk_size - 1))

    prepared_docs: List[Dict[str, Any]] = []
    for doc in payload.documents:
        text = (doc.text or "").strip()
        if not text:
            continue
        base_id = doc.document_id or str(uuid4())
        metadata = doc.metadata or {}
        chunks = _chunk_text(text, chunk_size, chunk_overlap)
        for idx, chunk in enumerate(chunks):
            prepared_docs.append(
                {
                    "id": f"{base_id}_chunk_{idx}",
                    "text": chunk,
                    "metadata": {
                        **metadata,
                        "chunk_index": idx,
                        "source_document_id": base_id,
                    },
                }
            )

    if not prepared_docs:
        raise HTTPException(status_code=400, detail="Не передано ни одного непустого документа")

    added = rag_pipeline.add_texts(prepared_docs)
    return {
        "chunks_indexed": added,
        "total_chunks": rag_pipeline.document_count,
        "chunk_size": chunk_size,
        "chunk_overlap": chunk_overlap,
    }


class RemoteTestRequest(BaseModel):
    api_key: str
    prompt: str = "Короткий пинг"
    model: Optional[str] = None
    max_tokens: int = 64


@app.post("/remote/test")
async def remote_test(payload: RemoteTestRequest):
    """Проверяет доступность удаленной LLM с переданным api_key (diag endpoint)."""
    reason = _remote_skip_reason(payload.api_key)
    if reason:
        raise HTTPException(status_code=400, detail=f"Remote LLM skipped: {reason}")
    try:
        remote_model = _select_remote_model(payload.model)
        messages = [
            {"role": "system", "content": "Ты — HalalAI. Ответь кратко одним предложением."},
            {"role": "user", "content": payload.prompt.strip() or "Пинг"},
        ]
        content = await asyncio.to_thread(
            call_remote_llm,
            messages,
            _sanitize_max_tokens(payload.max_tokens),
            payload.api_key,
            remote_model,
        )
        return {"status": "ok", "reply": content, "model": remote_model}
    except Exception as exc:
        logger.error("Remote test failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Remote test failed: {exc}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
