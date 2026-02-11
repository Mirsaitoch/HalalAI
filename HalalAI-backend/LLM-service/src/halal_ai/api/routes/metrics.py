"""Эндпоинты для мониторинга и метрик."""

from typing import Any, Dict, List

from fastapi import APIRouter, Query

from halal_ai.api.middleware import rate_limiter
from halal_ai.services.monitoring import metrics_collector

router = APIRouter(prefix="/metrics", tags=["metrics"])


@router.get("", summary="Получить сводку метрик")
async def get_metrics_summary() -> Dict[str, Any]:
    """
    Возвращает сводку всех метрик системы.
    
    Returns:
        Словарь с метриками запросов, латентности, RAG и моделей
    """
    return metrics_collector.get_summary()


@router.get("/queries/recent", summary="Получить последние запросы")
async def get_recent_queries(
    limit: int = Query(default=10, ge=1, le=100, description="Количество запросов")
) -> List[Dict[str, Any]]:
    """
    Возвращает последние запросы к системе.
    
    Args:
        limit: Максимальное количество запросов (1-100)
        
    Returns:
        Список последних запросов с метаданными
    """
    return metrics_collector.get_recent_queries(limit=limit)


@router.get("/queries/failed", summary="Получить неудачные запросы")
async def get_failed_queries(
    limit: int = Query(default=10, ge=1, le=100, description="Количество запросов")
) -> List[Dict[str, Any]]:
    """
    Возвращает последние неудачные запросы.
    
    Args:
        limit: Максимальное количество запросов (1-100)
        
    Returns:
        Список неудачных запросов с деталями ошибок
    """
    return metrics_collector.get_failed_queries(limit=limit)


@router.get("/queries/slow", summary="Получить медленные запросы")
async def get_slow_queries(
    threshold_ms: float = Query(
        default=5000,
        ge=100,
        le=60000,
        description="Порог латентности в мс"
    ),
    limit: int = Query(default=10, ge=1, le=100, description="Количество запросов")
) -> List[Dict[str, Any]]:
    """
    Возвращает медленные запросы, превышающие порог латентности.
    
    Args:
        threshold_ms: Порог латентности в миллисекундах (100-60000)
        limit: Максимальное количество запросов (1-100)
        
    Returns:
        Список медленных запросов, отсортированных по латентности
    """
    return metrics_collector.get_slow_queries(
        threshold_ms=threshold_ms,
        limit=limit
    )


@router.get("/health", summary="Проверка здоровья системы мониторинга")
async def metrics_health() -> Dict[str, Any]:
    """
    Проверяет работоспособность системы мониторинга.
    
    Returns:
        Статус системы мониторинга
    """
    summary = metrics_collector.get_summary()
    
    # Простая проверка здоровья на основе метрик
    is_healthy = True
    issues = []
    
    # Проверяем error rate
    if summary["requests"]["total"] > 10:
        if summary["requests"]["success_rate"] < 0.9:
            is_healthy = False
            issues.append("High error rate (< 90%)")
    
    # Проверяем latency
    if summary["latency"]["request_p95_ms"] > 10000:
        is_healthy = False
        issues.append("High P95 latency (> 10s)")
    
    # Проверяем RAG empty results
    if summary["rag"]["queries"] > 10:
        if summary["rag"]["empty_rate"] > 0.5:
            is_healthy = False
            issues.append("High RAG empty results rate (> 50%)")
    
    return {
        "status": "healthy" if is_healthy else "degraded",
        "issues": issues,
        "total_requests": summary["requests"]["total"],
        "success_rate": summary["requests"]["success_rate"],
        "p95_latency_ms": summary["latency"]["request_p95_ms"],
    }


@router.post("/reset", summary="Сбросить метрики (только для тестов)")
async def reset_metrics() -> Dict[str, str]:
    """
    Сбрасывает все метрики.
    
    ⚠️ ВНИМАНИЕ: Используйте только в тестовой среде!
    
    Returns:
        Сообщение об успешном сбросе
    """
    metrics_collector.reset()
    return {"message": "Metrics reset successfully"}


@router.get("/ratelimit", summary="Статистика rate limiter")
async def get_ratelimit_stats() -> Dict[str, Any]:
    """
    Возвращает статистику rate limiter.
    
    Returns:
        Информация об активных клиентах и настройках лимитов
    """
    return rate_limiter.get_stats()
