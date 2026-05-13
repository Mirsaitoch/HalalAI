"""TRACER BULLET #1: RAG Retrieval Accuracy Tests"""

import pytest


class TestRAGRetrieval:
    """Test that RAG correctly retrieves relevant Quran verses."""

    def test_retrieval_pork_query_returns_correct_surahs(self, quran_sample):
        """
        When user asks "что про свинину" (what about pork),
        RAG should retrieve verses from surahs 2, 5, 16 which mention pork prohibition.
        """
        from halal_rag.rag.retriever import SimpleRAG

        # Create RAG with sample documents
        rag = SimpleRAG(documents=quran_sample)

        # Search for pork query
        results = rag.search("что про свинину", top_k=3)

        # Assertions
        assert len(results) == 3, "Should return 3 results"

        # All results should have required fields
        for doc in results:
            assert 'id' in doc
            assert 'text' in doc
            assert 'sura' in doc
            assert 'score' in doc

        # Top results should be from surahs about pork (2, 5, 16)
        surahs_returned = [doc['sura'] for doc in results]
        assert surahs_returned[0] in [2, 5, 16], f"Top result should be about pork, got sura {surahs_returned[0]}"

        # Top result should have high relevance score (>0.5)
        assert results[0]['score'] > 0.5, f"Top result relevance should be >0.5, got {results[0]['score']}"

        # Text should mention "свинина" or "свиньи"
        top_text = results[0]['text'].lower()
        assert "свин" in top_text, "Top result should mention pork"

    def test_retrieval_preserves_all_document_metadata(self, quran_sample):
        """Retrieved documents should include all metadata."""
        from halal_rag.rag.retriever import SimpleRAG

        rag = SimpleRAG(documents=quran_sample)
        results = rag.search("свинина", top_k=1)

        doc = results[0]
        assert 'sura' in doc
        assert 'verse' in doc
        assert 'title' in doc
        assert 'subtitle' in doc
        assert isinstance(doc['sura'], int)

    def test_retrieval_with_empty_query_returns_empty(self, quran_sample):
        """Empty query should return empty results, not crash."""
        from halal_rag.rag.retriever import SimpleRAG

        rag = SimpleRAG(documents=quran_sample)
        results = rag.search("", top_k=3)

        assert results == []

    def test_retrieval_top_k_limit(self, quran_sample):
        """Should respect top_k limit."""
        from halal_rag.rag.retriever import SimpleRAG

        rag = SimpleRAG(documents=quran_sample)

        results_1 = rag.search("свинина", top_k=1)
        assert len(results_1) <= 1

        results_all = rag.search("свинина", top_k=100)
        assert len(results_all) <= len(quran_sample)
