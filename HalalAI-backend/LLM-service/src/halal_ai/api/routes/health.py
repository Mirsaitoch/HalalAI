"""Health check endpoints."""

from fastapi import APIRouter

from halal_ai.core import remote_llm_config

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    """Проверка здоровья сервиса."""
    return {
        "status": "healthy",
        "model": f"remote:{remote_llm_config.MODEL}",
    }


@router.get("/models")
async def available_models():
    """Возвращает список доступных удалённых моделей и модель по умолчанию."""
    return {
        "default_model": remote_llm_config.MODEL,
        "allowed_models": remote_llm_config.ALLOWED_MODELS or [],
    }
