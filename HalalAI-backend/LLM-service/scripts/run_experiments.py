#!/usr/bin/env python3
"""
Run all 9 RAG quality experiments.

Tests hypotheses about RAG, fine-tuning, and data representation.
Outputs retrieved verses for each configuration and question.
"""

import json
import sys
from dataclasses import dataclass
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from halal_rag.rag.retriever import SimpleRAG


@dataclass
class Config:
    """Experiment configuration"""
    id: str
    rag_enabled: bool
    model_name: str = None
    use_finetuned: bool = False
    use_chunks: bool = False

    def __str__(self):
        if not self.rag_enabled:
            return f"{self.id}: No RAG"
        ft = "Fine-tuned" if self.use_finetuned else "Base"
        data = "Chunk" if self.use_chunks else "Verse"
        return f"{self.id}: RAG + {self.model_name.split('/')[-1]} ({ft}) + {data}"


# Test questions (NOT in training data)
TEST_QUESTIONS = [
    "Что Коран говорит о запрете свинины?",
    "Какие аяты в Коране говорят о запрете алкоголя?",
    "Почему в исламе запрещен алкоголь?",
    "Что говорится в Коране о молитве и её значении?",
    "Как в Коране описывается поведение и скромность женщины?",
]

# Configurations
CONFIGS = [
    Config("C1", rag_enabled=False),
    Config(
        "C2",
        rag_enabled=True,
        model_name="sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
        use_finetuned=False,
        use_chunks=False
    ),
    Config(
        "C3",
        rag_enabled=True,
        model_name="sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
        use_finetuned=True,
        use_chunks=False
    ),
    Config(
        "C4",
        rag_enabled=True,
        model_name="ai-forever/sbert_large_nlu_ru",
        use_finetuned=False,
        use_chunks=False
    ),
    Config(
        "C5",
        rag_enabled=True,
        model_name="ai-forever/sbert_large_nlu_ru",
        use_finetuned=True,
        use_chunks=False
    ),
    Config(
        "C6",
        rag_enabled=True,
        model_name="sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
        use_finetuned=False,
        use_chunks=True
    ),
    Config(
        "C7",
        rag_enabled=True,
        model_name="sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
        use_finetuned=True,
        use_chunks=True
    ),
    Config(
        "C8",
        rag_enabled=True,
        model_name="ai-forever/sbert_large_nlu_ru",
        use_finetuned=False,
        use_chunks=True
    ),
    Config(
        "C9",
        rag_enabled=True,
        model_name="ai-forever/sbert_large_nlu_ru",
        use_finetuned=True,
        use_chunks=True
    ),
]


def load_documents(use_chunks: bool, base_path: Path) -> list[dict]:
    """Load verse or chunk documents"""
    if use_chunks:
        data_file = base_path / "data" / "quran_chunks.jsonl"
    else:
        data_file = base_path / "data" / "quran_ru.jsonl"

    if not data_file.exists():
        print(f"Error: {data_file} not found")
        return []

    docs = []
    with open(data_file, 'r', encoding='utf-8') as f:
        for line in f:
            docs.append(json.loads(line.strip()))

    return docs


def run_config(config: Config, results_dir: Path, base_path: Path):
    """Run a single configuration"""
    print(f"\n{'='*60}")
    print(f"Running {config}")
    print(f"{'='*60}")

    config_dir = results_dir / config.id
    config_dir.mkdir(parents=True, exist_ok=True)

    if not config.rag_enabled:
        # C1: No RAG
        print(f"{config.id}: No RAG — skipping retrieval")
        for i, question in enumerate(TEST_QUESTIONS, 1):
            output_file = config_dir / f"question_{i:02d}.txt"
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(f"Question {i}: {question}\n")
                f.write(f"Configuration: No RAG\n")
                f.write(f"Retrieved verses: None\n")
            print(f"  [{i}/5] {question[:50]}...")
        return

    # C2-C9: With RAG
    docs = load_documents(config.use_chunks, base_path)
    if not docs:
        print(f"Error: Could not load documents for {config.id}")
        return

    try:
        rag = SimpleRAG(
            documents=docs,
            embedding_model=config.model_name,
            use_finetuned=config.use_finetuned
        )
        print(f"✓ RAG initialized with {len(docs)} documents")
    except Exception as e:
        print(f"Error initializing RAG: {e}")
        return

    # Run queries
    for i, question in enumerate(TEST_QUESTIONS, 1):
        try:
            results = rag.search(question, top_k=3)
            output_file = config_dir / f"question_{i:02d}.txt"

            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(f"Question {i}: {question}\n")
                f.write(f"Configuration: {config}\n")
                f.write(f"Retrieved {len(results)} verses:\n")
                f.write(f"\n{'='*60}\n\n")

                for j, result in enumerate(results, 1):
                    f.write(f"Result {j} (score: {result.get('score', 'N/A'):.4f}):\n")
                    if config.use_chunks:
                        f.write(f"Sura {result['sura']}:{result['verse_start']}-{result['verse_end']}\n")
                    else:
                        f.write(f"Sura {result['sura']}:{result['verse']}\n")
                    f.write(f"Text: {result['text']}\n")
                    f.write(f"\n{'-'*60}\n\n")

            print(f"  [{i}/5] {question[:50]}... → {len(results)} results")

        except Exception as e:
            print(f"  [{i}/5] Error: {e}")
            output_file = config_dir / f"question_{i:02d}.txt"
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(f"Question {i}: {question}\n")
                f.write(f"Error: {e}\n")


def main():
    script_dir = Path(__file__).parent
    base_path = script_dir.parent
    results_dir = base_path / "results"

    results_dir.mkdir(parents=True, exist_ok=True)

    print(f"Running {len(CONFIGS)} configurations...")
    print(f"Test questions: {len(TEST_QUESTIONS)}")
    print(f"Results directory: {results_dir}")

    for config in CONFIGS:
        run_config(config, results_dir, base_path)

    print(f"\n{'='*60}")
    print(f"✓ All experiments complete!")
    print(f"Results saved to: {results_dir}")
    print(f"Next: Fill in evaluation scores in docs/experiment_tracker.md")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
