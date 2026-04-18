from pydantic import BaseModel


class ApiInfoResponse(BaseModel):
    name: str
    version: str
    description: str
    endpoints: dict[str, str]
