from pydantic import BaseModel


class ChatResponse(BaseModel):
    """Response model for /llm/chat endpoint"""
    reply: str
    used_remote: bool = False
    remote_error: str | None = None
