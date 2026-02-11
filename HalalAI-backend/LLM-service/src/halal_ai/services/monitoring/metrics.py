"""Система сбора метрик для мониторинга."""

import logging
import time
from collections import deque
from datetime import datetime
from functools import wraps
from typing import Any, Deque, Dict, List, Optional

logger = logging.getLogger(__name__)


class MetricsCollector:
    """
    Сборщик метрик для мониторинга системы.
    
    Собирает метрики о запросах, RAG поиске, латентности и ошибках.
    """
    
    def __init__(self, max_history: int = 1000):
        """
        Инициализирует коллектор метрик.
        
        Args:
            max_history: Максимальный размер истории запросов
        """
        self.max_history = max_history
        
        # Счетчики запросов
        self.total_requests = 0
        self.successful_requests = 0
        self.failed_requests = 0
        
        # RAG метрики
        self.rag_queries = 0
        self.rag_empty_results = 0
        self.rag_scores: Deque[float] = deque(maxlen=100)
        
        # Latency метрики (храним последние 100 значений для вычисления перцентилей)
        self.request_latencies: Deque[float] = deque(maxlen=100)
        self.rag_latencies: Deque[float] = deque(maxlen=100)
        self.llm_latencies: Deque[float] = deque(maxlen=100)
        
        # Модели
        self.remote_llm_calls = 0
        self.local_llm_calls = 0
        self.remote_llm_errors = 0
        
        # История запросов (для анализа)
        self.recent_queries: Deque[Dict[str, Any]] = deque(maxlen=max_history)
    
    def record_request(
        self,
        success: bool,
        latency_ms: float,
        used_rag: bool = False,
        used_remote: bool = False,
        query: Optional[str] = None,
        error: Optional[str] = None,
    ) -> None:
        """
        Записывает метрики запроса.
        
        Args:
            success: Успешность запроса
            latency_ms: Латентность в миллисекундах
            used_rag: Использовался ли RAG
            used_remote: Использовалась ли удаленная LLM
            query: Текст запроса (опционально)
            error: Текст ошибки (опционально)
        """
        self.total_requests += 1
        
        if success:
            self.successful_requests += 1
        else:
            self.failed_requests += 1
        
        self.request_latencies.append(latency_ms)
        
        if used_remote:
            self.remote_llm_calls += 1
            if not success:
                self.remote_llm_errors += 1
        else:
            self.local_llm_calls += 1
        
        # Сохраняем историю запросов
        if query or error:
            self.recent_queries.append({
                "timestamp": datetime.now().isoformat(),
                "query": query[:200] if query else None,  # Ограничиваем длину
                "success": success,
                "latency_ms": latency_ms,
                "used_rag": used_rag,
                "used_remote": used_remote,
                "error": error,
            })
    
    def record_rag_search(
        self,
        latency_ms: float,
        results_count: int,
        avg_score: Optional[float] = None,
    ) -> None:
        """
        Записывает метрики RAG поиска.
        
        Args:
            latency_ms: Латентность поиска в миллисекундах
            results_count: Количество найденных результатов
            avg_score: Средний score результатов (опционально)
        """
        self.rag_queries += 1
        self.rag_latencies.append(latency_ms)
        
        if results_count == 0:
            self.rag_empty_results += 1
        
        if avg_score is not None:
            self.rag_scores.append(avg_score)
    
    def record_llm_generation(self, latency_ms: float) -> None:
        """
        Записывает метрики генерации LLM.
        
        Args:
            latency_ms: Латентность генерации в миллисекундах
        """
        self.llm_latencies.append(latency_ms)
    
    def get_summary(self) -> Dict[str, Any]:
        """
        Возвращает сводку метрик.
        
        Returns:
            Словарь с метриками системы
        """
        return {
            "requests": {
                "total": self.total_requests,
                "successful": self.successful_requests,
                "failed": self.failed_requests,
                "success_rate": (
                    self.successful_requests / self.total_requests
                    if self.total_requests > 0 else 0
                ),
            },
            "latency": {
                "request_avg_ms": self._avg(self.request_latencies),
                "request_p50_ms": self._percentile(self.request_latencies, 0.50),
                "request_p95_ms": self._percentile(self.request_latencies, 0.95),
                "request_p99_ms": self._percentile(self.request_latencies, 0.99),
                "rag_avg_ms": self._avg(self.rag_latencies),
                "llm_avg_ms": self._avg(self.llm_latencies),
            },
            "rag": {
                "queries": self.rag_queries,
                "empty_results": self.rag_empty_results,
                "empty_rate": (
                    self.rag_empty_results / self.rag_queries
                    if self.rag_queries > 0 else 0
                ),
                "avg_score": self._avg(self.rag_scores),
            },
            "models": {
                "remote_calls": self.remote_llm_calls,
                "local_calls": self.local_llm_calls,
                "remote_errors": self.remote_llm_errors,
                "remote_error_rate": (
                    self.remote_llm_errors / self.remote_llm_calls
                    if self.remote_llm_calls > 0 else 0
                ),
            },
        }
    
    def get_recent_queries(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Возвращает последние запросы.
        
        Args:
            limit: Максимальное количество запросов
            
        Returns:
            Список последних запросов
        """
        return list(self.recent_queries)[-limit:]
    
    def get_failed_queries(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Возвращает последние неудачные запросы.
        
        Args:
            limit: Максимальное количество запросов
            
        Returns:
            Список неудачных запросов
        """
        failed = [q for q in self.recent_queries if not q["success"]]
        return failed[-limit:]
    
    def get_slow_queries(
        self,
        threshold_ms: float = 5000,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Возвращает медленные запросы.
        
        Args:
            threshold_ms: Порог латентности в миллисекундах
            limit: Максимальное количество запросов
            
        Returns:
            Список медленных запросов, отсортированных по латентности
        """
        slow = [q for q in self.recent_queries if q["latency_ms"] > threshold_ms]
        return sorted(slow, key=lambda x: x["latency_ms"], reverse=True)[:limit]
    
    def reset(self) -> None:
        """Сбрасывает все метрики (полезно для тестов)."""
        self.total_requests = 0
        self.successful_requests = 0
        self.failed_requests = 0
        self.rag_queries = 0
        self.rag_empty_results = 0
        self.rag_scores.clear()
        self.request_latencies.clear()
        self.rag_latencies.clear()
        self.llm_latencies.clear()
        self.remote_llm_calls = 0
        self.local_llm_calls = 0
        self.remote_llm_errors = 0
        self.recent_queries.clear()
    
    @staticmethod
    def _avg(values: Deque[float]) -> float:
        """Вычисляет среднее значение."""
        if not values:
            return 0.0
        return sum(values) / len(values)
    
    @staticmethod
    def _percentile(values: Deque[float], percentile: float) -> float:
        """Вычисляет перцентиль."""
        if not values:
            return 0.0
        sorted_values = sorted(values)
        index = int(len(sorted_values) * percentile)
        return sorted_values[min(index, len(sorted_values) - 1)]


# Глобальный экземпляр коллектора метрик
metrics_collector = MetricsCollector()


def track_request(func):
    """
    Декоратор для отслеживания метрик запроса.
    
    Использование:
        @track_request
        async def chat(request: ChatRequest):
            ...
    """
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        success = False
        error = None
        
        try:
            result = await func(*args, **kwargs)
            success = True
            return result
        except Exception as e:
            error = str(e)
            raise
        finally:
            latency_ms = (time.time() - start_time) * 1000
            
            # Пытаемся извлечь информацию о запросе
            query = None
            used_rag = False
            
            if args and hasattr(args[0], 'prompt'):
                query = args[0].prompt
                used_rag = getattr(args[0], 'use_rag', False)
            
            metrics_collector.record_request(
                success=success,
                latency_ms=latency_ms,
                used_rag=used_rag,
                used_remote=False,  # Определяется на уровне выше
                query=query,
                error=error,
            )
    
    return wrapper


def track_rag_search(func):
    """
    Декоратор для отслеживания RAG поиска.
    
    Использование:
        @track_rag_search
        def retrieve(self, query: str, top_k: int = 3):
            ...
    """
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        
        result = func(*args, **kwargs)
        
        latency_ms = (time.time() - start_time) * 1000
        results_count = len(result) if result else 0
        
        avg_score = None
        if result and len(result) > 0:
            scores = [r.get("score", 0) for r in result]
            avg_score = sum(scores) / len(scores) if scores else None
        
        metrics_collector.record_rag_search(
            latency_ms=latency_ms,
            results_count=results_count,
            avg_score=avg_score,
        )
        
        return result
    
    return wrapper
