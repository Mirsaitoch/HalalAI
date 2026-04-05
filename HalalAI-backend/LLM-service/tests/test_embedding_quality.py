"""Test embedding model quality for Quranic domain."""

import json
import sys
from pathlib import Path

import pytest
import torch

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from halal_rag.rag.embeddings import EmbeddingModel


@pytest.fixture
def embeddings():
    """Initialize embedding model once for all tests."""
    return EmbeddingModel(use_finetuned=True)


@pytest.fixture
def quranic_pairs():
    """Load test pairs."""
    pairs_file = Path(__file__).parent / "fixtures" / "quranic_pairs.json"
    with open(pairs_file) as f:
        return json.load(f)


def cosine_similarity(a: torch.Tensor, b: torch.Tensor) -> float:
    """Calculate cosine similarity between two embeddings."""
    return torch.nn.functional.cosine_similarity(
        a.unsqueeze(0), b.unsqueeze(0)
    ).item()


class TestEmbeddingRelevance:
    """Test that embeddings rank relevant content above irrelevant."""

    @pytest.mark.parametrize("pair_id", [
        "pork_prohibition",
        "alcohol_prohibition",
        "prayer_importance",
        "forbidden_foods",
        "lawful_meat",
        "fasting",
        "zakah",
        "hajj",
        "kindness_parents",
        "forbidden_wealth",
    ])
    def test_quranic_relevance(self, embeddings, quranic_pairs, pair_id):
        """All Quranic QA pairs: relevant should score higher than irrelevant."""
        pair = next(p for p in quranic_pairs if p["id"] == pair_id)

        query_emb = embeddings.encode_single(pair["query"])
        relevant_emb = embeddings.encode_single(pair["relevant"])
        irrelevant_emb = embeddings.encode_single(pair["irrelevant"])

        relevant_score = cosine_similarity(query_emb, relevant_emb)
        irrelevant_score = cosine_similarity(query_emb, irrelevant_emb)

        assert relevant_score > irrelevant_score, (
            f"Test '{pair_id}': Expected relevant ({relevant_score:.4f}) > "
            f"irrelevant ({irrelevant_score:.4f})"
        )

