
from pathlib import Path

import torch
from sentence_transformers import SentenceTransformer

from .interfaces import IEmbeddingEncoder


class EmbeddingModel(IEmbeddingEncoder):

    # Маппинг типов моделей на полные имена
    MODEL_MAPPING = {
        "paraphrase": "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
        "sbert": "ai-forever/sbert_large_nlu_ru",
    }

    def __init__(
        self,
        model_type: str = "paraphrase",
        use_finetuned: bool = False,
    ):
        model_name = self.MODEL_MAPPING.get(model_type, self.MODEL_MAPPING["paraphrase"])

        if use_finetuned:
            if "sbert" in model_type.lower():
                finetuned_dir = "sbert-quranic-embeddings"
            else:
                finetuned_dir = "quranic-embeddings"

            finetuned_path = (
                Path(__file__).parent.parent.parent.parent
                / "models"
                / finetuned_dir
            )
            if finetuned_path.exists():
                print(f"Loading fine-tuned model from {finetuned_path}")
                self.model = SentenceTransformer(str(finetuned_path), device="cpu")
                print("✓ Fine-tuned model loaded")
            else:
                print(
                    f"Fine-tuned model not found at {finetuned_path}, "
                    f"falling back to {model_name}"
                )
                try:
                    self.model = SentenceTransformer(
                        model_name, device="cpu", local_files_only=True
                    )
                except Exception:
                    print(f"Downloading model: {model_name}")
                    self.model = SentenceTransformer(model_name, device="cpu")
        else:
            try:
                self.model = SentenceTransformer(
                    model_name, device="cpu", local_files_only=True
                )
                print(f"✓ Loaded cached model: {model_name}")
            except Exception:
                print(f"📥 Downloading model: {model_name}")
                self.model = SentenceTransformer(model_name, device="cpu")
                print(f"✓ Model downloaded successfully")

        print("Getting embedding dimension...")
        self.embedding_dim = self.model.get_sentence_embedding_dimension()
        print(f"✓ Embedding dimension: {self.embedding_dim}")

    def encode(self, texts: list[str]) -> torch.Tensor:
        embeddings = self.model.encode(
            texts,
            convert_to_tensor=True,
            normalize_embeddings=True,
            show_progress_bar=False,
        )
        return embeddings.cpu()

    def encode_single(self, text: str) -> torch.Tensor:
        return self.encode([text])[0]
