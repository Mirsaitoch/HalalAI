"""TRACER BULLET #2: Quality & Hallucination Detection"""

import pytest


class TestQualityChecker:
    """Test that quality checker detects hallucinations."""

    def test_detect_hallucinated_citations(self):
        """
        When LLM cites a surah/verse not in sources,
        quality checker should mark as hallucination.
        """
        from halal_rag.quality.checker import QualityChecker

        sources = [
            {
                'sura': 2,
                'verse': '173',
                'text': 'Он запретил вам мертвечину, кровь, мясо свиньи...'
            },
            {
                'sura': 5,
                'verse': '3',
                'text': 'Запрещена вам мертвечина, кровь, мясо свиньи...'
            }
        ]

        # LLM output with hallucinated citation
        response = """
        Свинина запрещена в исламе. Это сказано в Коране:
        "Он запретил вам мясо свиньи" (сура 2, аят 173)
        Также в (сура 5, аят 3).
        И более того, в (сура 999, аят 1) говорится... (эта цитата выдумана)
        """

        checker = QualityChecker()
        quality_report = checker.check_response(response, sources)

        # Should detect that citation (999, 1) is hallucinated
        assert quality_report['hallucinations_detected']
        assert quality_report['invalid_citations']  # Should have invalid citations list
        assert any(cit['surah'] == 999 for cit in quality_report['invalid_citations'])

    def test_excellent_quality_with_valid_citations(self):
        """Response with only valid citations should have excellent quality."""
        from halal_rag.quality.checker import QualityChecker

        sources = [
            {'sura': 2, 'verse': '173', 'text': 'Запрещено мясо свиньи...'},
            {'sura': 5, 'verse': '3', 'text': 'Запрещена вам мертвечина...'}
        ]

        response = """
        Согласно Корану, свинина запрещена в исламе.
        В сура 2, аят 173 говорится: "Он запретил вам мясо свиньи..."
        В сура 5, аят 3 также упоминается это запрещение.
        """

        checker = QualityChecker()
        quality_report = checker.check_response(response, sources)

        assert not quality_report['hallucinations_detected']
        assert quality_report['quality'] == 'excellent'

    def test_poor_quality_all_citations_hallucinated(self):
        """Response with all hallucinated citations should be poor quality."""
        from halal_rag.quality.checker import QualityChecker

        sources = [
            {'sura': 2, 'verse': '173', 'text': 'Запрещено мясо свиньи...'}
        ]

        response = """
        Как сказано в (сура 999, аят 1) и (сура 888, аят 2),
        свинина запрещена. Это упоминается в (сура 777, аят 3).
        """

        checker = QualityChecker()
        quality_report = checker.check_response(response, sources)

        assert quality_report['quality'] in ['poor', 'critical']
        assert quality_report['hallucinations_detected']

    def test_quality_report_includes_required_fields(self):
        """Quality report should have all required fields."""
        from halal_rag.quality.checker import QualityChecker

        sources = [{'sura': 2, 'verse': '173', 'text': 'test'}]
        response = "Some response text"

        checker = QualityChecker()
        report = checker.check_response(response, sources)

        assert 'quality' in report
        assert 'hallucinations_detected' in report
        assert 'invalid_citations' in report
        assert 'risk_score' in report
        assert isinstance(report['quality'], str)
        assert isinstance(report['hallucinations_detected'], bool)
