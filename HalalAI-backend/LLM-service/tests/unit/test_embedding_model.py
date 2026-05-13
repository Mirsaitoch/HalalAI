"""EmbeddingModel с полностью подменённым SentenceTransformer."""

from pathlib import Path
from unittest.mock import MagicMock, patch

import torch

from halal_rag.rag.embeddings import EmbeddingModel


@patch("halal_rag.rag.embeddings.SentenceTransformer")
def test_embedding_model_loads_paraphrase_cached(mock_st):
    mock_model = MagicMock()
    mock_model.get_sentence_embedding_dimension.return_value = 8
    mock_st.return_value = mock_model

    emb = EmbeddingModel(model_type="paraphrase", use_finetuned=False)

    mock_st.assert_called_once()
    assert emb.embedding_dim == 8
    mock_model.encode.return_value = torch.randn(2, 8)
    t = emb.encode(["a", "b"])
    assert t.shape == (2, 8)
    mock_model.encode.assert_called_once()


@patch("halal_rag.rag.embeddings.SentenceTransformer")
def test_encode_single_uses_encode(mock_st):
    mock_model = MagicMock()
    mock_model.get_sentence_embedding_dimension.return_value = 4
    row = torch.tensor([[0.0, 1.0, 0.0, 0.0]])
    mock_model.encode.return_value = row
    mock_st.return_value = mock_model

    emb = EmbeddingModel(model_type="sbert", use_finetuned=False)
    one = emb.encode_single("hello")
    assert one.shape == (4,)


@patch("halal_rag.rag.embeddings.SentenceTransformer")
def test_finetuned_fallback_when_path_missing(mock_st, monkeypatch):
    mock_model = MagicMock()
    mock_model.get_sentence_embedding_dimension.return_value = 4
    mock_st.return_value = mock_model

    monkeypatch.setattr(Path, "exists", lambda self: False)

    EmbeddingModel(model_type="paraphrase", use_finetuned=True)
    assert mock_st.call_count >= 1
