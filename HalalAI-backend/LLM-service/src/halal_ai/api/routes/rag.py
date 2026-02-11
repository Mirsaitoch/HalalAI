"""RAG endpoints для работы с векторной базой знаний."""

import logging
from typing import Optional
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException

from halal_ai.api.dependencies import get_rag_pipeline
from halal_ai.core import (
    DEFAULT_CHUNK_OVERLAP,
    DEFAULT_CHUNK_SIZE,
    MAX_CHUNK_SIZE,
    MIN_CHUNK_SIZE,
    rag_config,
)
from halal_ai.models import IngestResponse, KnowledgeIngestRequest, RAGStatusResponse
from halal_ai.services.rag import RAGPipeline
from halal_ai.utils import chunk_text

router = APIRouter(prefix="/rag", tags=["rag"])
logger = logging.getLogger(__name__)


@router.get("/status", response_model=RAGStatusResponse)
async def rag_status(pipeline: Optional[RAGPipeline] = Depends(get_rag_pipeline)):
    """Возвращает состояние векторного индекса."""
    return RAGStatusResponse(
        enabled=rag_config.ENABLED,
        documents=pipeline.document_count if pipeline else 0,
        embedding_model=rag_config.EMBEDDING_MODEL,
        store_path=rag_config.VECTOR_STORE_PATH,
    )


@router.post("/documents", response_model=IngestResponse)
async def ingest_documents(
    payload: KnowledgeIngestRequest,
    pipeline: Optional[RAGPipeline] = Depends(get_rag_pipeline),
):
    """Добавляет новые документы в векторный индекс."""
    if not rag_config.ENABLED:
        raise HTTPException(status_code=503, detail="RAG отключен через конфигурацию")
    if pipeline is None:
        raise HTTPException(status_code=503, detail="RAG pipeline не инициализирован")

    chunk_size = max(MIN_CHUNK_SIZE, min(payload.chunk_size, MAX_CHUNK_SIZE))
    chunk_overlap = max(0, min(payload.chunk_overlap, chunk_size - 1))

    prepared_docs = []
    for doc in payload.documents:
        text = (doc.text or "").strip()
        if not text:
            continue
        
        base_id = doc.document_id or str(uuid4())
        metadata = doc.metadata or {}
        chunks = chunk_text(text, chunk_size, chunk_overlap)
        
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

    added = pipeline.add_texts(prepared_docs)
    return IngestResponse(
        chunks_indexed=added,
        total_chunks=pipeline.document_count,
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
    )
