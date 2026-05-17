"""Общие фикстуры для нефункциональных интеграционных тестов.

Фикстура `client` поднимает TestClient с замоканными файловой системой и RAG,
чтобы lifespan не требовал наличия реального файла quran_ru.jsonl.
"""
import io
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi.testclient import TestClient

import halal_rag.api.main as main_module


@pytest.fixture
def client(monkeypatch):
    mock_rag = MagicMock()
    mock_rag.search = MagicMock(return_value=[])

    # Патчим SimpleRAG, чтобы не требовалась sentence-transformers
    monkeypatch.setattr(main_module, "SimpleRAG", lambda *a, **kw: mock_rag)

    # Патчим OpenRouter, чтобы не нужен был API-ключ
    monkeypatch.setattr(
        "halal_rag.llm.open_router.OpenRouterClient.generate",
        AsyncMock(return_value="Тестовый ответ."),
    )

    # Патчим Path.exists, чтобы lifespan "нашёл" файл с данными
    real_exists = Path.exists

    def fake_exists(self):
        if "quran_ru.jsonl" in str(self):
            return True
        return real_exists(self)

    monkeypatch.setattr(Path, "exists", fake_exists)

    # Патчим open, чтобы lifespan прочитал минимальный JSONL без реального файла
    real_open = open

    def fake_open(file, *args, **kwargs):
        if "quran_ru.jsonl" in str(file):
            return io.StringIO('{"text": "Во имя Аллаха", "sura": 1, "verse": 1}\n')
        return real_open(file, *args, **kwargs)

    monkeypatch.setattr("builtins.open", fake_open)

    with TestClient(main_module.app) as c:
        yield c
