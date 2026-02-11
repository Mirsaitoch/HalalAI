"""Тесты для модуля проверки качества ответов."""

import pytest

from halal_ai.services.monitoring.quality import (
    CitationValidator,
    ResponseQualityChecker,
)


class TestCitationValidator:
    """Тесты для валидатора цитирований."""

    def test_extract_citations_format_1(self):
        """Тест извлечения цитат формата (сура X, аят Y)."""
        text = "Запрет упомянут в (сура 2, аят 173) и далее."
        citations = CitationValidator.extract_citations(text)
        assert (2, 173) in citations
        assert len(citations) >= 1

    def test_extract_citations_format_2(self):
        """Тест извлечения цитат формата X:Y."""
        text = "В аяте 2:173 говорится о запрете."
        citations = CitationValidator.extract_citations(text)
        assert (2, 173) in citations

    def test_extract_citations_multiple(self):
        """Тест извлечения нескольких цитат."""
        text = "В аяте 2:173 и 5:3 говорится о запрете."
        citations = CitationValidator.extract_citations(text)
        assert (2, 173) in citations
        assert (5, 3) in citations

    def test_extract_citations_no_duplicates(self):
        """Тест удаления дубликатов."""
        text = "В аяте 2:173, повторяю 2:173, снова 2:173."
        citations = CitationValidator.extract_citations(text)
        assert citations.count((2, 173)) == 1

    def test_extract_citations_empty(self):
        """Тест с текстом без цитат."""
        text = "Текст без упоминания конкретных аятов."
        citations = CitationValidator.extract_citations(text)
        assert citations == []

    def test_extract_source_ranges_single_ayah(self):
        """Тест извлечения одного аята из источников."""
        sources = [
            {
                "metadata": {
                    "surah": 2,
                    "ayah_from": 173,
                    "ayah_to": 173,
                }
            }
        ]
        ranges = CitationValidator.extract_source_ranges(sources)
        assert (2, 173) in ranges

    def test_extract_source_ranges_multiple_ayahs(self):
        """Тест извлечения диапазона аятов."""
        sources = [
            {
                "metadata": {
                    "surah": 5,
                    "ayah_from": 3,
                    "ayah_to": 5,
                }
            }
        ]
        ranges = CitationValidator.extract_source_ranges(sources)
        assert (5, 3) in ranges
        assert (5, 4) in ranges
        assert (5, 5) in ranges
        assert (5, 6) not in ranges

    def test_extract_source_ranges_multiple_sources(self):
        """Тест извлечения из нескольких источников."""
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}},
            {"metadata": {"surah": 5, "ayah_from": 3, "ayah_to": 4}},
        ]
        ranges = CitationValidator.extract_source_ranges(sources)
        assert (2, 173) in ranges
        assert (5, 3) in ranges
        assert (5, 4) in ranges

    def test_validate_citations_all_valid(self):
        """Тест с валидными цитатами."""
        text = "В аяте 2:173 говорится о запрете."
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}}
        ]
        result = CitationValidator.validate_citations(text, sources)
        
        assert result["all_valid"] is True
        assert result["total_citations"] == 1
        assert result["valid_citations"] == 1
        assert result["invalid_citations"] == []
        assert result["hallucination_risk"] == "low"

    def test_validate_citations_invalid(self):
        """Тест с невалидными цитатами."""
        text = "В аяте 2:164 говорится о запрете."
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}}
        ]
        result = CitationValidator.validate_citations(text, sources)
        
        assert result["all_valid"] is False
        assert result["total_citations"] == 1
        assert result["valid_citations"] == 0
        assert len(result["invalid_citations"]) == 1
        assert result["invalid_citations"][0] == {"surah": 2, "ayah": 164}
        assert result["hallucination_risk"] == "high"

    def test_validate_citations_mixed(self):
        """Тест со смешанными цитатами (валидные и невалидные)."""
        text = "В аяте 2:173 и 2:164 говорится о запрете."
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}}
        ]
        result = CitationValidator.validate_citations(text, sources)
        
        assert result["all_valid"] is False
        assert result["total_citations"] == 2
        assert result["valid_citations"] == 1
        assert len(result["invalid_citations"]) == 1
        assert result["hallucination_risk"] == "medium"

    def test_validate_citations_no_citations_no_sources(self):
        """Тест без цитат и источников."""
        text = "Общее описание без цитат."
        sources = []
        result = CitationValidator.validate_citations(text, sources)
        
        assert result["all_valid"] is True
        assert result["total_citations"] == 0
        assert result["hallucination_risk"] == "low"

    def test_validate_citations_no_citations_with_sources(self):
        """Тест без цитат, но с источниками (подозрительно)."""
        text = "Общее описание без цитат."
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}}
        ]
        result = CitationValidator.validate_citations(text, sources)
        
        assert result["all_valid"] is True
        assert result["total_citations"] == 0
        assert result["hallucination_risk"] == "medium"

    def test_detect_confident_claims(self):
        """Тест обнаружения уверенных утверждений."""
        text = "Свинина точно запрещена всегда."
        result = CitationValidator.detect_confident_claims(text)
        
        assert result["has_confident_claims"] is True
        assert result["count"] >= 2  # "точно" и "всегда"

    def test_detect_confident_claims_none(self):
        """Тест без уверенных утверждений."""
        text = "Согласно источникам, свинина может быть запрещена."
        result = CitationValidator.detect_confident_claims(text)
        
        assert result["has_confident_claims"] is False
        assert result["count"] == 0


class TestResponseQualityChecker:
    """Тесты для полной проверки качества ответа."""

    def test_excellent_response(self):
        """Тест отличного ответа с валидными цитатами."""
        text = "В аяте 2:173 говорится о запрете свинины."
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}}
        ]
        
        checker = ResponseQualityChecker()
        result = checker.check_response(text, sources)
        
        assert result["quality"] == "excellent"
        assert result["risk_score"] == 0
        assert result["issues"] == []

    def test_poor_response_hallucinations(self):
        """Тест плохого ответа с галлюцинациями."""
        text = "В аяте 2:164 и 2:165 говорится о запрете свинины."
        sources = [
            {"metadata": {"surah": 5, "ayah_from": 3, "ayah_to": 5}}
        ]
        
        checker = ResponseQualityChecker()
        result = checker.check_response(text, sources)
        
        assert result["quality"] in ["poor", "critical"]
        assert result["risk_score"] > 5
        assert len(result["issues"]) > 0
        assert any("Невалидные цитаты" in issue for issue in result["issues"])

    def test_response_with_sources_but_no_citations(self):
        """Тест с источниками, но без цитирования."""
        text = "Свинина запрещена в исламе."
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}}
        ]
        
        checker = ResponseQualityChecker()
        result = checker.check_response(text, sources)
        
        assert result["quality"] in ["good", "acceptable"]
        assert "Источники предоставлены, но не процитированы" in result["issues"]

    def test_confident_claims_without_sources(self):
        """Тест с уверенными утверждениями без источников."""
        text = "Свинина всегда запрещена без исключений."
        sources = []
        
        checker = ResponseQualityChecker()
        result = checker.check_response(text, sources)
        
        assert result["quality"] in ["acceptable", "poor"]
        assert any(
            "Уверенные утверждения без источников" in issue
            for issue in result["issues"]
        )

    def test_mixed_quality_response(self):
        """Тест ответа среднего качества."""
        text = "В аяте 2:173 говорится о запрете. Также точно известно, что это всегда харам."
        sources = [
            {"metadata": {"surah": 2, "ayah_from": 173, "ayah_to": 173}}
        ]
        
        checker = ResponseQualityChecker()
        result = checker.check_response(text, sources)
        
        # Должно быть acceptable или good
        assert result["quality"] in ["acceptable", "good", "excellent"]


class TestRealWorldScenarios:
    """Тесты на реальных сценариях."""

    def test_real_hallucination_case(self):
        """
        Реальный случай: модель упоминает аяты 2:164, 2:165,
        но в sources их нет.
        """
        response_text = (
            "В Коране свинина всегда харам. В аяте 2:164 говорится: «Из того, что дано мне в откровении, "
            "я нахожу запрещенным употреблять в пищу только мертвечину, пролитую кровь и мясо свиньи». "
            "Также в аяте 2:165 упоминается, что мясо свиньи — недозволено."
        )
        sources = [
            {
                "metadata": {
                    "surah": 4,
                    "surah_name_ru": "АЛЬ-МАИДА",
                    "ayah_from": 95,
                    "ayah_to": 97,
                    "ayah_range": "95-97",
                }
            },
            {
                "metadata": {
                    "surah": 5,
                    "surah_name_ru": "АЛЬ-АНАМ",
                    "ayah_from": 145,
                    "ayah_to": 147,
                    "ayah_range": "145-147",
                }
            },
            {
                "metadata": {
                    "surah": 2,
                    "surah_name_ru": "АЛЬ-БАКАРА",
                    "ayah_from": 71,
                    "ayah_to": 73,
                    "ayah_range": "71-73",
                }
            },
        ]
        
        checker = ResponseQualityChecker()
        result = checker.check_response(response_text, sources)
        
        # Проверяем что детектор нашел проблему
        assert result["quality"] in ["poor", "critical"]
        assert result["citation_validation"]["all_valid"] is False
        
        # Должны быть найдены невалидные цитаты 2:164 и 2:165
        invalid = result["citation_validation"]["invalid_citations"]
        invalid_pairs = [(c["surah"], c["ayah"]) for c in invalid]
        assert (2, 164) in invalid_pairs
        assert (2, 165) in invalid_pairs
        
        # Risk score должен быть высоким
        assert result["risk_score"] > 5
        assert len(result["issues"]) > 0
