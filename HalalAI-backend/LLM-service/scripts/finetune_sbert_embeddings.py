#!/usr/bin/env python3
"""Fine-tune SBERT Large NLU RU on Quranic QA pairs."""

import json
import sys
from pathlib import Path

from sentence_transformers import SentenceTransformer, InputExample, losses
from torch.utils.data import DataLoader

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))


def load_training_pairs(pairs_file: Path) -> list[InputExample]:
    """Load training pairs and convert to InputExample format."""
    with open(pairs_file) as f:
        pairs = json.load(f)

    examples = []
    for pair in pairs:
        # Positive example: query + relevant
        examples.append(
            InputExample(
                texts=[pair["query"], pair["relevant"]], label=1.0
            )
        )
        # Negative example: query + irrelevant
        examples.append(
            InputExample(
                texts=[pair["query"], pair["irrelevant"]], label=0.0
            )
        )

    return examples


def main():
    """Fine-tune SBERT Large NLU RU model."""
    # Paths
    pairs_file = Path(__file__).parent.parent / "tests" / "fixtures" / "quranic_pairs.json"
    model_output_dir = (
        Path(__file__).parent.parent / "models" / "sbert-quranic-embeddings"
    )
    model_output_dir.mkdir(parents=True, exist_ok=True)

    # Load SBERT model
    model_name = "ai-forever/sbert_large_nlu_ru"
    print(f"📥 Loading SBERT Large NLU RU...")
    model = SentenceTransformer(model_name, device="cpu")
    print(f"✓ Model loaded successfully")
    print(f"  Embedding dimension: {model.get_embedding_dimension()}")

    # Load training data
    print(f"\n📚 Loading training pairs from {pairs_file}...")
    train_examples = load_training_pairs(pairs_file)
    print(f"✓ Loaded {len(train_examples)} training examples")
    print(f"  ({len(train_examples)//2} positive + {len(train_examples)//2} negative pairs)")

    # Create data loader
    train_dataloader = DataLoader(
        train_examples,
        shuffle=True,
        batch_size=4,
        pin_memory=False
    )

    # Loss function - Cosine Similarity Loss
    train_loss = losses.CosineSimilarityLoss(model)

    # Fine-tune with conservative settings
    print(f"\n⏳ Fine-tuning model...")
    print(f"  Epochs: 20")
    print(f"  Batch size: 4")
    print(f"  Learning rate: 2e-5 (conservative)")
    print(f"  Warmup steps: 50")

    model.fit(
        train_objectives=[(train_dataloader, train_loss)],
        epochs=20,
        warmup_steps=50,
        weight_decay=0.01,
        show_progress_bar=True,
    )

    # Save
    print(f"\n💾 Saving model to {model_output_dir}...")
    model.save(str(model_output_dir))
    print("✅ Fine-tuning complete!")
    print(f"\n📊 Model info:")
    print(f"  Base model: {model_name}")
    print(f"  Training pairs: {len(train_examples)//2}")
    print(f"  Output directory: {model_output_dir}")
    print(f"  Embedding dimension: 1024")


if __name__ == "__main__":
    main()
