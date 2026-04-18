
from typing import Any

from .embeddings import EmbeddingModel
from .vector_store import VectorStore
from .interfaces import IRAGPipeline, IEmbeddingEncoder, IVectorSearcher


class SimpleRAG(IRAGPipeline):
    def __init__(
        self,
        documents: list[dict[str, Any]],
        model_type: str = "paraphrase",  # "paraphrase" или "sbert"
        use_finetuned: bool = False,
    ):

        self.embeddings: IEmbeddingEncoder = EmbeddingModel(model_type=model_type, use_finetuned=use_finetuned)
        self.store: IVectorSearcher = VectorStore()

        texts = [doc['text'] for doc in documents]
        embeddings = self.embeddings.encode(texts)

        self.store.add_documents(documents, embeddings)

    def search(self, query: str, top_k: int = 3) -> list[dict[str, Any]]:
        if not query or not query.strip():
            return []

        query_embedding = self.embeddings.encode_single(query)

        return self.store.search(query_embedding, top_k=top_k)
