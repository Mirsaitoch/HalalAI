
import re
from typing import Any

class QualityChecker:

    def check_response(
        self,
        response: str,
        sources: list[dict[str, Any]],
    ) -> dict[str, Any]:

        cited = self._extract_citations(response)

        valid_citations = self._get_valid_citations(sources)

        invalid_tuples = [c for c in cited if tuple(c) not in valid_citations]
        invalid = [{'surah': s, 'ayah': a} for s, a in invalid_tuples]

        hallucinations_detected = len(invalid) > 0
        total_citations = len(cited)

        risk_score = 0
        if invalid:
            risk_score += len(invalid) * 3

        if risk_score == 0 and total_citations > 0:
            quality = 'excellent'
        elif risk_score <= 3:
            quality = 'good'
        elif risk_score <= 6:
            quality = 'acceptable'
        elif risk_score <= 10:
            quality = 'poor'
        else:
            quality = 'critical'

        return {
            'quality': quality,
            'hallucinations_detected': hallucinations_detected,
            'invalid_citations': invalid,
            'total_citations': total_citations,
            'risk_score': risk_score,
        }

    def _extract_citations(self, text: str) -> list[tuple[int, int]]:
        citations = []

        patterns = [
            r'\(сура\s+(\d+),\s*аят\s+(\d+)\)',
            r'сура\s+(\d+),\s*аят\s+(\d+)',
            r'\(сура\s+(\d+),\s*аяты\s+(\d+)',
        ]

        for pattern in patterns:
            for match in re.finditer(pattern, text, re.IGNORECASE):
                try:
                    surah = int(match.group(1))
                    ayah = int(match.group(2))
                    citations.append((surah, ayah))
                except (ValueError, IndexError):
                    continue

        return citations

    def _get_valid_citations(self, sources: list[dict[str, Any]]) -> set[tuple[int, int]]:
        valid = set()

        for source in sources:
            surah = source.get('sura')
            verse = source.get('verse')

            if surah is not None and verse is not None:
                try:
                    valid.add((int(surah), int(verse)))
                except (ValueError, TypeError):
                    continue

        return valid
