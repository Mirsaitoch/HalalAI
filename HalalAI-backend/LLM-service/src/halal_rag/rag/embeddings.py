
from pathlib import Path

import torch
from sentence_transformers import SentenceTransformer

class EmbeddingModel:

    def __init__(
        self,
        model_name: str = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
        use_finetuned: bool = False,
    ):

        if use_finetuned:

            finetuned_path = (
                Path(__file__).parent.parent.parent.parent
                / "models"
                / "quranic-embeddings"
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
                self.model = SentenceTransformer(
                    model_name, device="cpu", local_files_only=True
                )
        else:
            self.model = SentenceTransformer(
                model_name, device="cpu", local_files_only=True
            )
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
