"""Мониторинг качества ответов и детекция галлюцинаций."""

import logging
import re
from typing import Any, Dict, List, Set, Tuple

logger = logging.getLogger(__name__)


class CitationValidator:
    """
    Валидатор цитирований для предотвращения галлюцинаций.
    
    Проверяет что все ссылки на аяты присутствуют в источниках RAG.
    """
    
    @staticmethod
    def extract_citations(text: str) -> List[Tuple[int, int]]:
        """
        Извлекает все цитаты из текста в формате (сура X, аят Y).
        
        Args:
            text: Текст ответа
            
        Returns:
            Список кортежей (номер_суры, номер_аята)
        """
        citations = []
        
        # Паттерны для поиска цитат
        patterns = [
            r'\(сура\s+(\d+),\s*аят\s+(\d+)\)',  # (сура 2, аят 173)
            r'сура\s+(\d+),\s*аят\s+(\d+)',      # сура 2, аят 173
            r'аят\s+(\d+):(\d+)',                # аят 2:173
            r'(\d+):(\d+)',                      # 2:173 (простой формат)
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                try:
                    surah = int(match.group(1))
                    ayah = int(match.group(2))
                    citations.append((surah, ayah))
                except (ValueError, IndexError):
                    continue
        
        # Удаляем дубликаты
        return list(set(citations))
    
    @staticmethod
    def extract_source_ranges(sources: List[Dict[str, Any]]) -> Set[Tuple[int, int]]:
        """
        Извлекает все валидные комбинации (сура, аят) из источников.
        
        Args:
            sources: Список источников из RAG
            
        Returns:
            Множество валидных кортежей (номер_суры, номер_аята)
        """
        valid_citations = set()
        
        for source in sources:
            metadata = source.get("metadata", {})
            surah = metadata.get("surah")
            
            if surah is None:
                continue
            
            # Извлекаем диапазон аятов
            ayah_from = metadata.get("ayah_from")
            ayah_to = metadata.get("ayah_to")
            
            if ayah_from is not None and ayah_to is not None:
                # Добавляем все аяты в диапазоне
                for ayah in range(int(ayah_from), int(ayah_to) + 1):
                    valid_citations.add((int(surah), ayah))
            elif ayah_from is not None:
                # Только один аят
                valid_citations.add((int(surah), int(ayah_from)))
        
        return valid_citations
    
    @classmethod
    def validate_citations(
        cls,
        text: str,
        sources: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Проверяет корректность всех цитирований в тексте.
        
        Args:
            text: Текст ответа с цитатами
            sources: Список источников из RAG
            
        Returns:
            Словарь с результатами валидации:
            - all_valid: bool - все ли цитаты валидны
            - total_citations: int - общее количество цитат
            - valid_citations: int - количество валидных цитат
            - invalid_citations: list - список невалидных цитат
            - hallucination_risk: str - уровень риска галлюцинации
        """
        found_citations = cls.extract_citations(text)
        valid_source_citations = cls.extract_source_ranges(sources)
        
        invalid_citations = []
        valid_count = 0
        
        for citation in found_citations:
            if citation in valid_source_citations:
                valid_count += 1
            else:
                invalid_citations.append(citation)
                logger.warning(
                    "🚨 Невалидная цитата: сура %d, аят %d (отсутствует в sources)",
                    citation[0], citation[1]
                )
        
        total = len(found_citations)
        all_valid = len(invalid_citations) == 0
        
        # Определяем уровень риска
        if not found_citations:
            risk = "medium" if sources else "low"  # Нет цитат - подозрительно если есть sources
        elif all_valid:
            risk = "low"
        elif invalid_citations and valid_count > 0:
            risk = "medium"  # Есть и валидные, и невалидные
        else:
            risk = "high"  # Все цитаты невалидны
        
        return {
            "all_valid": all_valid,
            "total_citations": total,
            "valid_citations": valid_count,
            "invalid_citations": [
                {"surah": s, "ayah": a} for s, a in invalid_citations
            ],
            "hallucination_risk": risk,
        }
    
    @staticmethod
    def detect_confident_claims(text: str) -> Dict[str, Any]:
        """
        Определяет уверенные утверждения без подтверждения.
        
        Args:
            text: Текст ответа
            
        Returns:
            Словарь с найденными утверждениями
        """
        confident_phrases = [
            r'\bточно\b',
            r'\bопределенно\b',
            r'\bбезусловно\b',
            r'\bвсегда\b',
            r'\bникогда\b',
            r'\bобязательно\b',
            r'\bстрого запрещено\b',
            r'\bбез исключений\b',
        ]
        
        found = []
        for phrase_pattern in confident_phrases:
            matches = re.finditer(phrase_pattern, text, re.IGNORECASE)
            for match in matches:
                found.append({
                    "phrase": match.group(0),
                    "position": match.start(),
                })
        
        return {
            "has_confident_claims": len(found) > 0,
            "count": len(found),
            "phrases": found[:5],  # Ограничиваем 5 для краткости
        }


class ResponseQualityChecker:
    """
    Проверяет качество ответа: цитирования, галлюцинации, полноту.
    """
    
    def __init__(self):
        self.validator = CitationValidator()
    
    def check_response(
        self,
        response_text: str,
        sources: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Полная проверка качества ответа.
        
        Args:
            response_text: Текст ответа LLM
            sources: Список источников из RAG
            
        Returns:
            Словарь с результатами проверки качества
        """
        # 1. Проверка цитирований
        citation_check = self.validator.validate_citations(response_text, sources)
        
        # 2. Проверка уверенных утверждений
        confident_claims = self.validator.detect_confident_claims(response_text)
        
        # 3. Проверка наличия источников
        has_sources = len(sources) > 0
        has_citations = citation_check["total_citations"] > 0
        
        # 4. Определяем общий risk score
        risk_score = 0
        
        # Невалидные цитаты - высокий риск
        if citation_check["invalid_citations"]:
            risk_score += len(citation_check["invalid_citations"]) * 3
        
        # Уверенные утверждения без источников
        if confident_claims["has_confident_claims"] and not has_sources:
            risk_score += confident_claims["count"] * 2
        
        # Цитаты есть, но все невалидны - очень высокий риск
        if has_citations and citation_check["total_citations"] > 0:
            if citation_check["valid_citations"] == 0:
                risk_score += 5
        
        # Источники есть, но цитат нет
        if has_sources and not has_citations:
            risk_score += 1
        
        # Определяем качество
        if risk_score == 0:
            quality = "excellent"
        elif risk_score <= 2:
            quality = "good"
        elif risk_score <= 5:
            quality = "acceptable"
        elif risk_score <= 10:
            quality = "poor"
        else:
            quality = "critical"
        
        return {
            "quality": quality,
            "risk_score": risk_score,
            "citation_validation": citation_check,
            "confident_claims": confident_claims,
            "has_sources": has_sources,
            "has_citations": has_citations,
            "issues": self._generate_issues(
                citation_check,
                confident_claims,
                has_sources,
                has_citations
            ),
        }
    
    @staticmethod
    def _generate_issues(
        citation_check: Dict[str, Any],
        confident_claims: Dict[str, Any],
        has_sources: bool,
        has_citations: bool,
    ) -> List[str]:
        """Генерирует список проблем с ответом."""
        issues = []
        
        if citation_check["invalid_citations"]:
            invalid = citation_check["invalid_citations"]
            issues.append(
                f"Невалидные цитаты: {len(invalid)} "
                f"(например: сура {invalid[0]['surah']}, аят {invalid[0]['ayah']})"
            )
        
        if has_sources and not has_citations:
            issues.append("Источники предоставлены, но не процитированы")
        
        if confident_claims["has_confident_claims"] and not has_sources:
            issues.append(
                f"Уверенные утверждения без источников: "
                f"{confident_claims['count']} раз"
            )
        
        if has_citations and citation_check["valid_citations"] == 0:
            issues.append("Все цитаты невалидны - возможная галлюцинация")
        
        return issues


# Глобальный экземпляр проверки качества
quality_checker = ResponseQualityChecker()
