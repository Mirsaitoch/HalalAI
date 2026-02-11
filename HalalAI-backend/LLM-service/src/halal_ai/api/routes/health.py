"""Health check endpoints."""

from fastapi import APIRouter, Depends

from halal_ai.api.dependencies import get_local_llm
from halal_ai.core import remote_llm_config
from halal_ai.services.llm import LocalLLM

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check(llm: LocalLLM = Depends(get_local_llm)):
    """Проверка здоровья сервиса."""
    return {
        "status": "healthy",
        "model": llm.model_name,
    }


@router.get("/models")
async def available_models():
    """Возвращает список доступных удалённых моделей и модель по умолчанию."""
    return {
        "default_model": remote_llm_config.MODEL,
        "allowed_models": remote_llm_config.ALLOWED_MODELS or [],
    }
