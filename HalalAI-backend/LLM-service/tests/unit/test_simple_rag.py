"""SimpleRAG с подменой EmbeddingModel — без sentence-transformers."""

from unittest.mock import MagicMock, patch

import torch

from halal_rag.rag.retriever import SimpleRAG


def _fake_embedding_model():
    class FakeEmb:
        dim = 4

        def encode(self, texts: list[str]) -> torch.Tensor:
            n = len(texts)
            return torch.eye(self.dim, dtype=torch.float32)[:n, :]

        def encode_single(self, text: str) -> torch.Tensor:
            t = text.strip().lower()
            if t == "alpha":
                return torch.tensor([1.0, 0.0, 0.0, 0.0])
            return torch.tensor([0.0, 1.0, 0.0, 0.0])

    return FakeEmb()


def test_simple_rag_empty_query_returns_empty():
    fake = _fake_embedding_model()
    mock_cls = MagicMock(return_value=fake)
    docs = [
        {"text": "first", "sura": 1, "verse": "1"},
        {"text": "second", "sura": 2, "verse": "2"},
    ]
    with patch("halal_rag.rag.retriever.EmbeddingModel", mock_cls):
        rag = SimpleRAG(docs, model_type="paraphrase", use_finetuned=False)
    assert rag.search("") == []
    assert rag.search("   ") == []


def test_simple_rag_search_returns_ranked_docs():
    fake = _fake_embedding_model()
    mock_cls = MagicMock(return_value=fake)
    docs = [
        {"text": "alpha doc", "sura": 1, "verse": "1"},
        {"text": "beta doc", "sura": 2, "verse": "2"},
    ]
    with patch("halal_rag.rag.retriever.EmbeddingModel", mock_cls):
        rag = SimpleRAG(docs, model_type="paraphrase", use_finetuned=False)
    hits = rag.search("alpha", top_k=2)
    assert len(hits) >= 1
    assert hits[0]["text"] == "alpha doc"
    assert "score" in hits[0]
