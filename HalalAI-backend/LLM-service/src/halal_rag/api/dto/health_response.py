from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    rag_ready: str
    llm_ready: str
