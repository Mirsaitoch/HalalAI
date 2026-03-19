"""Chat endpoints для генерации ответов."""

import asyncio
import logging
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException

from halal_ai.api.dependencies import get_rag_pipeline
from halal_ai.core import ALLOWED_MESSAGE_ROLES, llm_config, rag_config, remote_llm_config
from halal_ai.core.exceptions import RemoteLLMException
from halal_ai.models import ChatRequest, ChatResponse, RemoteTestRequest
from halal_ai.services.llm import (
    call_remote_llm,
    get_effective_api_key,
    get_remote_skip_reason,
    select_remote_model,
)
from halal_ai.services.monitoring import quality_checker
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
    get_rag_relevance_keywords,
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


def check_response_quality(content: str, rag_sources: List[Dict[str, Any]]) -> None:
    """Проверяет качество ответа и логирует проблемы."""
    if not rag_sources:
        return

    quality_report = quality_checker.check_response(content, rag_sources)

    if quality_report["quality"] in ["poor", "critical"]:
        logger.warning(
            "🚨 Низкое качество ответа! Quality: %s, Risk score: %d",
            quality_report["quality"],
            quality_report["risk_score"],
        )
        for issue in quality_report.get("issues", []):
            logger.warning("  ⚠️  %s", issue)

    citation_info = quality_report["citation_validation"]
    if not citation_info["all_valid"]:
        logger.warning(
            "❌ Обнаружены невалидные цитаты: %d из %d",
            len(citation_info["invalid_citations"]),
            citation_info["total_citations"],
        )
        for invalid_cite in citation_info["invalid_citations"]:
            logger.warning(
                "   📖 Невалидная цитата: сура %d, аят %d",
                invalid_cite["surah"],
                invalid_cite["ayah"],
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

    query_variants = generate_query_variants(query_text)
    logger.info("Сгенерировано %d вариантов запроса для RAG поиска", len(query_variants))

    rag_filters = build_rag_filters(query_text)

    all_sources = []
    seen_ids = set()

    for idx, variant in enumerate(query_variants):
        logger.info("Ищем по варианту #%d: '%s'", idx + 1, variant[:60])

        if rag_filters and idx == 0:
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

        for source in sources:
            source_id = source.get("id")
            if source_id and source_id not in seen_ids:
                seen_ids.add(source_id)
                all_sources.append(source)

        if len(all_sources) >= rag_top_k * 2:
            logger.info("Собрано достаточно источников (%d), останавливаем поиск", len(all_sources))
            break

    relevance_keywords = get_rag_relevance_keywords(query_text)
    if relevance_keywords:
        with_keyword = []
        without_keyword = []
        for src in all_sources:
            text = (src.get("text") or "").lower()
            if any(kw in text for kw in relevance_keywords):
                with_keyword.append(src)
            else:
                without_keyword.append(src)
        with_keyword.sort(key=lambda x: x.get("score", 0), reverse=True)
        without_keyword.sort(key=lambda x: x.get("score", 0), reverse=True)
        all_sources = with_keyword + without_keyword
    else:
        all_sources.sort(key=lambda x: x.get("score", 0), reverse=True)

    rag_sources = all_sources[:rag_top_k]
    logger.info("RAG вернул %d уникальных контекстов из %d найденных", len(rag_sources), len(all_sources))
    return rag_sources


async def handle_chat_request(
    request: ChatRequest,
    pipeline: Optional[RAGPipeline],
) -> ChatResponse:
    """Выполняет полноценный пайплайн генерации (подготовка, RAG, remote LLM)."""
    logger.info(
        "Получен запрос: prompt_provided=%s, messages=%s",
        bool(request.prompt),
        len(request.messages) if request.messages else 0,
    )

    try:
        messages = prepare_messages(request)

        rag_sources: List[Dict[str, Any]] = []

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

        # Используем пользовательский ключ или серверный
        effective_api_key = get_effective_api_key(request.api_key)
        if not effective_api_key:
            raise HTTPException(
                status_code=503,
                detail="AI service unavailable: no API key configured (set REMOTE_LLM_API_KEY)",
            )

        remote_model = select_remote_model(request.remote_model)
        logger.info("Используем remote LLM (model=%s, max_tokens=%s).", remote_model, max_new_tokens)

        try:
            content = await asyncio.to_thread(
                call_remote_llm,
                messages,
                max_new_tokens,
                effective_api_key,
                remote_model,
            )
        except RemoteLLMException as exc:
            logger.error("Remote LLM вернула ошибку: %s", exc)
            raise HTTPException(status_code=503, detail=f"AI service error: {exc}")

        logger.info("Ответ модели [remote:%s]: %s символов", remote_model, len(content))
        check_response_quality(content, rag_sources)

        return ChatResponse(
            reply=content,
            sources=serialize_sources(rag_sources) or None,
            model=f"remote:{remote_model}",
            used_remote=True,
            remote_error="",
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Ошибка при генерации: %s", exc)
        raise HTTPException(status_code=500, detail=f"Generation error: {str(exc)}")


@router.post("/chat", response_model=ChatResponse, response_model_exclude_none=False)
async def chat(
    request: ChatRequest,
    pipeline: Optional[RAGPipeline] = Depends(get_rag_pipeline),
):
    """Генерация ответа на основе промпта или истории сообщений."""
    try:
        return await execute_with_timeout(
            handle_chat_request(request, pipeline),
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
        effective_key = get_effective_api_key(payload.api_key)
        content = await asyncio.to_thread(
            call_remote_llm,
            messages,
            sanitize_max_tokens(payload.max_tokens),
            effective_key,
            remote_model,
        )
        return {"status": "ok", "reply": content, "model": remote_model}
    except Exception as exc:
        logger.error("Remote test failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Remote test failed: {exc}")
