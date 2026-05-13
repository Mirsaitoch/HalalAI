"""DependencyContainer."""

import os
from unittest.mock import MagicMock

import pytest

from halal_rag.api import dependencies
from halal_rag.api.services import ChatService


def test_set_rag_clears_chat_service():
    dependencies.DependencyContainer._chat_service = MagicMock()
    mock_rag = MagicMock()
    dependencies.set_rag(mock_rag)
    assert dependencies.get_rag() is mock_rag
    assert dependencies.DependencyContainer._chat_service is None


def test_set_llm_client_clears_chat_service():
    dependencies.DependencyContainer._chat_service = MagicMock()
    client = MagicMock()
    dependencies.set_llm_client(client)
    assert dependencies.get_llm_client() is client
    assert dependencies.DependencyContainer._chat_service is None


def test_get_llm_client_without_key_returns_none(monkeypatch):
    monkeypatch.delenv("OPEN_ROUTER_KEY", raising=False)
    dependencies.DependencyContainer._llm_client = None
    assert dependencies.get_llm_client() is None


def test_get_llm_client_with_env_creates_openrouter(monkeypatch):
    dependencies.DependencyContainer._llm_client = None
    monkeypatch.setenv("OPEN_ROUTER_KEY", "test-key-openrouter")
    client = dependencies.get_llm_client()
    assert client is not None
    assert dependencies.DependencyContainer._llm_client is client


def test_get_chat_service_requires_rag():
    dependencies.DependencyContainer._rag = None
    dependencies.DependencyContainer._chat_service = None
    assert dependencies.get_chat_service() is None


def test_get_chat_service_builds_singleton(monkeypatch):
    dependencies.DependencyContainer._rag = MagicMock()
    dependencies.DependencyContainer._llm_client = None
    dependencies.DependencyContainer._chat_service = None
    monkeypatch.setenv("OPEN_ROUTER_KEY", "k")
    svc = dependencies.get_chat_service()
    assert isinstance(svc, ChatService)
    assert dependencies.get_chat_service() is svc
