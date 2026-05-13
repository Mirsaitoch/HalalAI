"""Pydantic DTO."""

import pytest
from pydantic import ValidationError

from halal_rag.api.dto import ApiInfoResponse, ChatRequest, ChatResponse, HealthResponse, RootResponse


def test_chat_request_defaults():
    r = ChatRequest(messages=[{"role": "user", "content": "hi"}])
    assert r.max_tokens == 256
    assert r.use_rag is True
    assert r.temperature == 0.7


def test_chat_request_invalid_messages_type():
    with pytest.raises(ValidationError):
        ChatRequest(messages="not-a-list")  # type: ignore[arg-type]


def test_chat_response_model():
    r = ChatResponse(reply="ok", used_remote=True, remote_error=None)
    assert r.reply == "ok"


def test_health_response():
    h = HealthResponse(status="ok", rag_ready="ready", llm_ready="not initialized")
    assert h.rag_ready == "ready"


def test_api_info_and_root():
    a = ApiInfoResponse(name="n", version="1", description="d", endpoints={"a": "/a"})
    assert a.endpoints["a"] == "/a"
    root = RootResponse(message="m", docs="/docs")
    assert root.docs == "/docs"
