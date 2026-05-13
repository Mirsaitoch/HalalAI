"""Дополнительные ветки EmbeddingModel."""

from unittest.mock import MagicMock, patch

from halal_rag.rag.embeddings import EmbeddingModel


@patch("halal_rag.rag.embeddings.SentenceTransformer")
def test_cached_model_fails_then_downloads(mock_st):
    mock_model = MagicMock()
    mock_model.get_sentence_embedding_dimension.return_value = 4
    mock_st.side_effect = [OSError("no local cache"), mock_model]

    emb = EmbeddingModel(model_type="paraphrase", use_finetuned=False)

    assert emb.embedding_dim == 4
    assert mock_st.call_count == 2


@patch("halal_rag.rag.embeddings.SentenceTransformer")
def test_finetuned_sbert_uses_sbert_dir_name(mock_st, monkeypatch):
    mock_model = MagicMock()
    mock_model.get_sentence_embedding_dimension.return_value = 4
    mock_st.return_value = mock_model
    monkeypatch.setattr("halal_rag.rag.embeddings.Path.exists", lambda self: False)

    EmbeddingModel(model_type="sbert", use_finetuned=True)

    first = str(mock_st.call_args_list[0][0][0])
    assert "sbert" in first.lower() or "ai-forever" in first


@patch("halal_rag.rag.embeddings.SentenceTransformer")
def test_finetuned_local_dir_found_loads_from_path(mock_st, monkeypatch):
    """Ветка exists() == True: загрузка с диска (стр. 37–39)."""
    mock_model = MagicMock()
    mock_model.get_sentence_embedding_dimension.return_value = 8
    mock_st.return_value = mock_model

    def exists_true_for_quranic(self):
        s = str(self).replace("\\", "/")
        return "models/quranic-embeddings" in s or s.endswith("quranic-embeddings")

    monkeypatch.setattr("halal_rag.rag.embeddings.Path.exists", exists_true_for_quranic)

    emb = EmbeddingModel(model_type="paraphrase", use_finetuned=True)

    assert emb.embedding_dim == 8
    local_arg = str(mock_st.call_args[0][0])
    assert "quranic-embeddings" in local_arg


@patch("halal_rag.rag.embeddings.SentenceTransformer")
def test_finetuned_missing_inner_st_fails_then_downloads(mock_st, monkeypatch):
    """Ветка except внутри use_finetuned: 49–51."""
    mock_model = MagicMock()
    mock_model.get_sentence_embedding_dimension.return_value = 4
    mock_st.side_effect = [OSError("no hub cache"), mock_model]
    monkeypatch.setattr("halal_rag.rag.embeddings.Path.exists", lambda self: False)

    emb = EmbeddingModel(model_type="paraphrase", use_finetuned=True)

    assert emb.embedding_dim == 4
    assert mock_st.call_count == 2
