"""Тесты VectorStore без загрузки моделей эмбеддингов."""

import pytest
import torch

from halal_rag.rag.vector_store import VectorStore


def test_search_empty_store_returns_empty():
    store = VectorStore()
    q = torch.randn(8)
    assert store.search(q, top_k=3) == []


def test_add_and_search_returns_scores_and_metadata():
    store = VectorStore()
    docs = [
        {"id": "a", "text": "one", "sura": 1, "verse": "1"},
        {"id": "b", "text": "two", "sura": 2, "verse": "2"},
    ]
    emb = torch.tensor([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]], dtype=torch.float32)
    store.add_documents(docs, emb)

    query = torch.tensor([1.0, 0.0, 0.0], dtype=torch.float32)
    results = store.search(query, top_k=1)
    assert len(results) == 1
    assert results[0]["id"] == "a"
    assert results[0]["score"] == pytest.approx(1.0, abs=0.01)


def test_search_one_dimensional_query_embedding():
    store = VectorStore()
    docs = [{"id": "x", "text": "t"}]
    store.add_documents(docs, torch.randn(1, 4))
    q = torch.randn(4)
    out = store.search(q, top_k=1)
    assert len(out) == 1
    assert "score" in out[0]


def test_top_k_capped_by_document_count():
    store = VectorStore()
    docs = [{"id": str(i), "text": str(i)} for i in range(5)]
    emb = torch.eye(5)
    store.add_documents(docs, emb)
    results = store.search(torch.tensor([1.0, 0.0, 0.0, 0.0, 0.0]), top_k=100)
    assert len(results) == 5


def test_append_documents_extends_embeddings():
    store = VectorStore()
    store.add_documents([{"id": "1"}], torch.randn(1, 3))
    store.add_documents([{"id": "2"}], torch.randn(1, 3))
    assert len(store.documents) == 2
    assert store.embeddings is not None
    assert store.embeddings.shape[0] == 2
