"""Chat endpoints для генерации ответов."""

import asyncio
import logging
from typing import Any, Dict, List, Optional

import torch
from fastapi import APIRouter, Depends, HTTPException

from halal_ai.api.dependencies import get_local_llm, get_rag_pipeline
from halal_ai.core import ALLOWED_MESSAGE_ROLES, llm_config, rag_config
from halal_ai.core.exceptions import RemoteLLMException, TimeoutException
from halal_ai.models import ChatRequest, ChatResponse, RemoteTestRequest
from halal_ai.services.llm import (
    LocalLLM,
    call_remote_llm,
    get_remote_skip_reason,
    select_remote_model,
    should_use_remote_llm,
)
from halal_ai.services.prompts import (
    ensure_system_prompt,
    inject_halal_guardrail,
    inject_rag_context,
    inject_surah_guardrail,
)
from halal_ai.services.rag import RAGPipeline
from halal_ai.utils import (
    build_rag_filters,
    extract_last_user_query,
    generate_query_variants,
    normalize_food_query,
    serialize_sources,
)

router = APIRouter(tags=["chat"])
logger = logging.getLogger(__name__)


async def execute_with_timeout(coro, stage: str):
    """Ограничивает выполнение корутины по времени."""
    try:
        return await asyncio.wait_for(coro, timeout=llm_config.REQUEST_TIMEOUT_SECONDS)
    except asyncio.TimeoutError:
        logger.error("%s превысила лимит %s секунд.", stage, llm_config.REQUEST_TIMEOUT_SECONDS)
        raise HTTPException(
            status_code=504,
            detail=f"{stage} timed out after {llm_config.REQUEST_TIMEOUT_SECONDS} seconds",
        )


def sanitize_max_tokens(value: Optional[int]) -> int:
    """Нормализует значение max_tokens."""
    if value is None:
        return llm_config.MAX_NEW_TOKENS
    return max(llm_config.MIN_NEW_TOKENS, min(value, llm_config.MAX_NEW_TOKENS))


def sanitize_top_k(value: Optional[int]) -> int:
    """Нормализует количество RAG-контекстов."""
    if value is None:
        return rag_config.DEFAULT_TOP_K
    return max(1, min(value, 10))


def prepare_messages(request: ChatRequest) -> List[Dict[str, str]]:
    """Нормализует и проверяет структуру сообщений из запроса."""
    normalized: List[Dict[str, str]] = []

    if request.messages:
        for msg in request.messages:
            role = (msg.role or "").strip().lower()
            if role not in ALLOWED_MESSAGE_ROLES:
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

    with_system = ensure_system_prompt(normalized)
    guarded = inject_halal_guardrail(with_system)
    return guarded


async def retrieve_rag_context(
    query_text: str,
    rag_top_k: int,
    pipeline: Optional[RAGPipeline],
) -> List[Dict[str, Any]]:
    """Получает контекст из RAG если доступен."""
    if not rag_config.ENABLED:
        logger.info("RAG отключен через конфиг, пропускаем поиск контекста.")
        return []
    
    if pipeline is None:
        logger.info("RAG запрошен, но пайплайн не инициализирован.")
        return []
    
    if pipeline.document_count == 0:
        logger.info("RAG включен, но индекс пуст. Требуются данные для наполнения.")
        return []
    
    if not query_text:
        logger.info("Не удалось определить пользовательский запрос для RAG.")
        return []

    # Генерируем множественные варианты запроса для улучшения поиска
    query_variants = generate_query_variants(query_text)
    logger.info("Сгенерировано %d вариантов запроса для RAG поиска", len(query_variants))
    logger.info("Варианты: %s", query_variants[:3])  # Показываем первые 3
    
    rag_filters = build_rag_filters(query_text)
    
    # Ищем по всем вариантам запроса и объединяем результаты
    all_sources = []
    seen_ids = set()
    
    for idx, variant in enumerate(query_variants):
        logger.info("Ищем по варианту #%d: '%s'", idx + 1, variant[:60])
        
        if rag_filters and idx == 0:  # Фильтры только для первого (основного) варианта
            logger.info("Попытка RAG с фильтрами: %s", rag_filters)
            sources = await asyncio.to_thread(
                pipeline.retrieve,
                variant,
                top_k=rag_top_k,
                filters=rag_filters or None,
                search_top_k=rag_config.SEARCH_TOP_K,
            )
        else:
            sources = await asyncio.to_thread(
                pipeline.retrieve,
                variant,
                top_k=rag_top_k,
                search_top_k=rag_config.SEARCH_TOP_K,
            )
        
        # Добавляем новые источники, избегая дубликатов
        for source in sources:
            source_id = source.get("id")
            if source_id and source_id not in seen_ids:
                seen_ids.add(source_id)
                all_sources.append(source)
        
        # Если нашли достаточно результатов, можем остановиться
        if len(all_sources) >= rag_top_k * 2:
            logger.info("Собрано достаточно источников (%d), останавливаем поиск", len(all_sources))
            break
    
    # Сортируем по score и берем top_k
    all_sources.sort(key=lambda x: x.get("score", 0), reverse=True)
    rag_sources = all_sources[:rag_top_k]
    
    logger.info("RAG вернул %d уникальных контекстов из %d найденных", len(rag_sources), len(all_sources))
    return rag_sources


async def handle_chat_request(
    request: ChatRequest,
    llm: LocalLLM,
    pipeline: Optional[RAGPipeline],
) -> ChatResponse:
    """Выполняет полноценный пайплайн генерации (подготовка, RAG, remote/local)."""
    logger.info(
        "Получен запрос: prompt_provided=%s, messages=%s",
        bool(request.prompt),
        len(request.messages) if request.messages else 0,
    )

    try:
        messages = prepare_messages(request)
        messages = llm.limit_history_length(messages)
        logger.info("Используется история из %s сообщений (после нормализации)", len(messages))

        rag_sources: List[Dict[str, Any]] = []
        remote_error: Optional[str] = None

        if request.use_rag:
            query_text = extract_last_user_query(messages)
            rag_top_k = sanitize_top_k(request.rag_top_k)
            rag_sources = await retrieve_rag_context(query_text, rag_top_k, pipeline)

            if rag_sources:
                surah_numbers = [
                    ctx.get("metadata", {}).get("surah")
                    for ctx in rag_sources
                    if ctx.get("metadata", {}).get("surah") is not None
                ]
                if surah_numbers:
                    messages = inject_surah_guardrail(messages, surah_numbers)
                messages = inject_rag_context(messages, rag_sources)
                logger.info("Добавлено %s контекстов из RAG.", len(rag_sources))

        max_new_tokens = sanitize_max_tokens(request.max_tokens)

        # Пытаемся использовать удаленную LLM если есть API ключ
        if should_use_remote_llm(request.api_key):
            remote_model = select_remote_model(request.remote_model)
            logger.info(
                "Используем удаленную LLM по пользовательскому ключу (model=%s, max_tokens=%s).",
                remote_model,
                max_new_tokens,
            )
            try:
                content = await asyncio.to_thread(
                    call_remote_llm,
                    messages,
                    max_new_tokens,
                    request.api_key,
                    remote_model,
                )
                logger.info("Ответ модели [remote:%s]: %s символов", remote_model, len(content))
                return ChatResponse(
                    reply=content,
                    sources=serialize_sources(rag_sources) or None,
                    model=f"remote:{remote_model}",
                    used_remote=True,
                    remote_error="",
                )
            except RemoteLLMException as remote_exc:
                logger.info(
                    "Удаленная LLM недоступна или вернула ошибку (%s). Переходим на локальную модель.",
                    remote_exc,
                )
                remote_error = str(remote_exc)
        else:
            reason = get_remote_skip_reason(request.api_key)
            if reason:
                logger.info("Remote LLM пропущен: %s", reason)

        # Используем локальную модель
        content = await asyncio.to_thread(llm.generate, messages, max_new_tokens)
        if not content:
            logger.info("Ответ локальной модели пустой.")
        logger.info("Ответ модели [local:%s]: %s символов", llm.model_name, len(content))
        
        return ChatResponse(
            reply=content,
            sources=serialize_sources(rag_sources) or None,
            model=f"local:{llm.model_name}",
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


@router.post("/chat", response_model=ChatResponse, response_model_exclude_none=False)
async def chat(
    request: ChatRequest,
    llm: LocalLLM = Depends(get_local_llm),
    pipeline: Optional[RAGPipeline] = Depends(get_rag_pipeline),
):
    """Генерация ответа на основе промпта или истории сообщений."""
    try:
        return await execute_with_timeout(
            handle_chat_request(request, llm, pipeline),
            "LLM generation",
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Ошибка при генерации: %s", exc)
        raise HTTPException(status_code=500, detail=f"Generation error: {str(exc)}")


@router.post("/remote/test")
async def remote_test(payload: RemoteTestRequest):
    """Проверяет доступность удаленной LLM с переданным api_key (diag endpoint)."""
    reason = get_remote_skip_reason(payload.api_key)
    if reason:
        raise HTTPException(status_code=400, detail=f"Remote LLM skipped: {reason}")
    
    try:
        remote_model = select_remote_model(payload.model)
        messages = [
            {"role": "system", "content": "Ты — HalalAI. Ответь кратко одним предложением."},
            {"role": "user", "content": payload.prompt.strip() or "Пинг"},
        ]
        content = await asyncio.to_thread(
            call_remote_llm,
            messages,
            sanitize_max_tokens(payload.max_tokens),
            payload.api_key,
            remote_model,
        )
        return {"status": "ok", "reply": content, "model": remote_model}
    except Exception as exc:
        logger.error("Remote test failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Remote test failed: {exc}")
