
from typing import Any
import torch
from torch import nn

from .interfaces import IVectorSearcher


class VectorStore(IVectorSearcher):

    def __init__(self):
        self.documents: list[dict[str, Any]] = []
        self.embeddings: torch.Tensor | None = None

    def add_documents(self, documents: list[dict[str, Any]], embeddings: torch.Tensor):
        self.documents.extend(documents)

        if self.embeddings is None:
            self.embeddings = embeddings
        else:
            self.embeddings = torch.cat([self.embeddings, embeddings], dim=0)

    def search(self, query_embedding: torch.Tensor, top_k: int = 3) -> list[dict[str, Any]]:
        if self.embeddings is None or not self.documents:
            return []

        if query_embedding.dim() == 1:
            query_embedding = query_embedding.unsqueeze(0)

        query = nn.functional.normalize(query_embedding, p=2, dim=1)
        doc_embeddings = nn.functional.normalize(self.embeddings, p=2, dim=1)

        scores = torch.matmul(doc_embeddings, query.T).squeeze(1)

        k = min(top_k, len(self.documents))
        top_scores, indices = torch.topk(scores, k=k)

        results = []
        for score, idx in zip(top_scores.tolist(), indices.tolist()):
            doc = self.documents[idx].copy()
            doc['score'] = float(score)
            results.append(doc)

        return results
