"""Pydantic модели для RAG."""

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class KnowledgeDocument(BaseModel):
    """Документ для добавления в базу знаний."""

    document_id: Optional[str] = Field(None, description="Уникальный ID документа")
    text: str = Field(..., description="Текст документа")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Метаданные документа")


class KnowledgeIngestRequest(BaseModel):
    """Запрос на добавление документов в RAG."""

    documents: List[KnowledgeDocument] = Field(..., description="Список документов")
    chunk_size: int = Field(800, description="Размер чанка")
    chunk_overlap: int = Field(100, description="Перекрытие между чанками")


class RAGStatusResponse(BaseModel):
    """Статус RAG системы."""

    enabled: bool = Field(..., description="Включен ли RAG")
    documents: int = Field(..., description="Количество документов в индексе")
    embedding_model: str = Field(..., description="Модель для эмбеддингов")
    store_path: str = Field(..., description="Путь к векторному хранилищу")


class IngestResponse(BaseModel):
    """Ответ на добавление документов."""

    chunks_indexed: int = Field(..., description="Количество добавленных чанков")
    total_chunks: int = Field(..., description="Общее количество чанков в индексе")
    chunk_size: int = Field(..., description="Использованный размер чанка")
    chunk_overlap: int = Field(..., description="Использованное перекрытие")
