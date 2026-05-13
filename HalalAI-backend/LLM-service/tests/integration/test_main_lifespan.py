"""Ветки startup lifespan в halal_rag.api.main (без полной загрузки RAG где возможно)."""

from pathlib import Path
from unittest.mock import patch

import pytest

import halal_rag.api.main as main


@pytest.mark.asyncio
async def test_lifespan_raises_when_quran_file_missing(monkeypatch):
    real_exists = Path.exists

    def fake_exists(self):
        if self.name == "quran_ru.jsonl" and "data" in str(self).replace("\\", "/"):
            return False
        return real_exists(self)

    monkeypatch.setattr(Path, "exists", fake_exists)
    with pytest.raises(FileNotFoundError, match="Quran data not found"):
        async with main.lifespan(main.app):
            pass


@pytest.mark.asyncio
async def test_lifespan_propagates_when_json_invalid():
    with patch.object(main.json, "loads", side_effect=ValueError("corrupt jsonl")):
        with pytest.raises(ValueError, match="corrupt jsonl"):
            async with main.lifespan(main.app):
                pass
