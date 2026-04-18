from pydantic import BaseModel


class ChatRequest(BaseModel):
    """Request model for /llm/chat endpoint"""
    messages: list[dict[str, str]]
    max_tokens: int = 256
    api_key: str | None = None
    remote_model: str = "qwen/qwen3.6-plus:free"
    temperature: float = 0.7
