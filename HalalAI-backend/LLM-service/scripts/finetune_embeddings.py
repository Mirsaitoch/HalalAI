#!/usr/bin/env python3
"""Fine-tune embedding model on Quranic QA pairs."""

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
    """Fine-tune embedding model."""
    # Paths
    pairs_file = Path(__file__).parent.parent / "tests" / "fixtures" / "quranic_pairs.json"
    model_output_dir = (
        Path(__file__).parent.parent / "models" / "quranic-embeddings"
    )
    model_output_dir.mkdir(parents=True, exist_ok=True)

    # Load model
    print("Loading model...")
    model = SentenceTransformer(
        "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
        local_files_only=True
    )

    # Load training data
    print(f"Loading training pairs from {pairs_file}...")
    train_examples = load_training_pairs(pairs_file)
    print(f"Loaded {len(train_examples)} training examples")

    # Create data loader
    train_dataloader = DataLoader(train_examples, shuffle=True, batch_size=16)

    # Loss function - Contrastive loss for similarity learning
    train_loss = losses.CosineSimilarityLoss(model)

    # Fine-tune
    print(f"\nFine-tuning model...")
    model.fit(
        train_objectives=[(train_dataloader, train_loss)],
        epochs=50,
        warmup_steps=100,
        show_progress_bar=True,
    )

    # Save
    print(f"\nSaving model to {model_output_dir}...")
    model.save(str(model_output_dir))
    print("✅ Done!")


if __name__ == "__main__":
    main()
