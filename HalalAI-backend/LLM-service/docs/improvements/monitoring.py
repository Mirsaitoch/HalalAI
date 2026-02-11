"""
Система мониторинга и метрик для LLM сервиса.

Включает:
1. Prometheus метрики для отслеживания производительности
2. Логирование запросов и ответов
3. Мониторинг качества RAG
4. Отслеживание ошибок и латентности
"""

import time
from typing import Any, Dict, List, Optional
from datetime import datetime
from functools import wraps
import logging

# Для production рекомендуется использовать prometheus_client
# from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry

logger = logging.getLogger(__name__)


class MetricsCollector:
    """Сборщик метрик для мониторинга системы."""
    
    def __init__(self):
        # Счетчики запросов
        self.total_requests = 0
        self.successful_requests = 0
        self.failed_requests = 0
        
        # RAG метрики
        self.rag_queries = 0
        self.rag_cache_hits = 0
        self.rag_empty_results = 0
        self.avg_rag_score = []
        
        # Latency метрики
        self.request_latencies = []
        self.rag_latencies = []
        self.llm_latencies = []
        
        # Модели
        self.remote_llm_calls = 0
        self.local_llm_calls = 0
        self.remote_llm_errors = 0
        
        # История запросов (для анализа)
        self.recent_queries = []
        self.max_history = 1000
        
    def record_request(
        self,
        success: bool,
        latency_ms: float,
        used_rag: bool = False,
        used_remote: bool = False,
        query: Optional[str] = None,
        error: Optional[str] = None,
    ):
        """Записывает метрики запроса."""
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
        if query:
            self.recent_queries.append({
                "timestamp": datetime.now().isoformat(),
                "query": query[:200],  # Ограничиваем длину
                "success": success,
                "latency_ms": latency_ms,
                "used_rag": used_rag,
                "used_remote": used_remote,
                "error": error,
            })
            
            # Ограничиваем размер истории
            if len(self.recent_queries) > self.max_history:
                self.recent_queries = self.recent_queries[-self.max_history:]
    
    def record_rag_search(
        self,
        latency_ms: float,
        results_count: int,
        avg_score: Optional[float] = None,
        cache_hit: bool = False,
    ):
        """Записывает метрики RAG поиска."""
        self.rag_queries += 1
        self.rag_latencies.append(latency_ms)
        
        if cache_hit:
            self.rag_cache_hits += 1
        
        if results_count == 0:
            self.rag_empty_results += 1
        
        if avg_score is not None:
            self.avg_rag_score.append(avg_score)
    
    def record_llm_generation(self, latency_ms: float):
        """Записывает метрики генерации LLM."""
        self.llm_latencies.append(latency_ms)
    
    def get_summary(self) -> Dict[str, Any]:
        """Возвращает сводку метрик."""
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
                "request_avg_ms": (
                    sum(self.request_latencies) / len(self.request_latencies)
                    if self.request_latencies else 0
                ),
                "request_p95_ms": self._percentile(self.request_latencies, 0.95),
                "request_p99_ms": self._percentile(self.request_latencies, 0.99),
                "rag_avg_ms": (
                    sum(self.rag_latencies) / len(self.rag_latencies)
                    if self.rag_latencies else 0
                ),
                "llm_avg_ms": (
                    sum(self.llm_latencies) / len(self.llm_latencies)
                    if self.llm_latencies else 0
                ),
            },
            "rag": {
                "queries": self.rag_queries,
                "cache_hits": self.rag_cache_hits,
                "cache_hit_rate": (
                    self.rag_cache_hits / self.rag_queries
                    if self.rag_queries > 0 else 0
                ),
                "empty_results": self.rag_empty_results,
                "avg_score": (
                    sum(self.avg_rag_score) / len(self.avg_rag_score)
                    if self.avg_rag_score else 0
                ),
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
        """Возвращает последние запросы."""
        return self.recent_queries[-limit:]
    
    def get_failed_queries(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Возвращает последние неудачные запросы."""
        failed = [q for q in self.recent_queries if not q["success"]]
        return failed[-limit:]
    
    def get_slow_queries(self, threshold_ms: float = 5000, limit: int = 10) -> List[Dict[str, Any]]:
        """Возвращает медленные запросы."""
        slow = [q for q in self.recent_queries if q["latency_ms"] > threshold_ms]
        return sorted(slow, key=lambda x: x["latency_ms"], reverse=True)[:limit]
    
    @staticmethod
    def _percentile(values: List[float], percentile: float) -> float:
        """Вычисляет перцентиль."""
        if not values:
            return 0.0
        sorted_values = sorted(values)
        index = int(len(sorted_values) * percentile)
        return sorted_values[min(index, len(sorted_values) - 1)]


# Глобальный экземпляр коллектора метрик
metrics_collector = MetricsCollector()


def track_request(func):
    """Декоратор для отслеживания метрик запроса."""
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
            used_remote = False
            
            if args and hasattr(args[0], 'prompt'):
                query = args[0].prompt
                used_rag = getattr(args[0], 'use_rag', False)
            
            metrics_collector.record_request(
                success=success,
                latency_ms=latency_ms,
                used_rag=used_rag,
                used_remote=used_remote,
                query=query,
                error=error,
            )
    
    return wrapper


def track_rag_search(func):
    """Декоратор для отслеживания RAG поиска."""
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
            cache_hit=False,
        )
        
        return result
    
    return wrapper


class RAGQualityMonitor:
    """Мониторинг качества RAG ответов."""
    
    def __init__(self):
        self.feedback_data = []
        self.hallucination_checks = []
        
    def log_retrieval(
        self,
        query: str,
        retrieved_docs: List[Dict[str, Any]],
        final_answer: str,
    ):
        """Логирует результаты retrieval для последующего анализа."""
        self.feedback_data.append({
            "timestamp": datetime.now().isoformat(),
            "query": query,
            "num_docs": len(retrieved_docs),
            "doc_scores": [d.get("score", 0) for d in retrieved_docs],
            "answer_length": len(final_answer),
        })
    
    def check_citation_quality(
        self,
        answer: str,
        sources: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Проверяет качество цитирования источников в ответе.
        
        Returns:
            Словарь с метриками качества:
            - has_citations: есть ли цитаты в ответе
            - citation_count: количество цитат
            - all_sources_cited: все ли источники процитированы
        """
        import re
        
        # Ищем паттерны цитат: (сура XX, аят YY)
        citation_pattern = r'\(сура\s+\d+,\s*аят\s+\d+\)'
        citations = re.findall(citation_pattern, answer, re.IGNORECASE)
        
        has_citations = len(citations) > 0
        citation_count = len(citations)
        
        # Проверяем, что все источники процитированы
        source_surahs = set()
        for source in sources:
            metadata = source.get("metadata", {})
            if "surah" in metadata:
                source_surahs.add(metadata["surah"])
        
        cited_surahs = set()
        for citation in citations:
            match = re.search(r'сура\s+(\d+)', citation, re.IGNORECASE)
            if match:
                cited_surahs.add(int(match.group(1)))
        
        all_sources_cited = len(source_surahs - cited_surahs) == 0
        
        return {
            "has_citations": has_citations,
            "citation_count": citation_count,
            "all_sources_cited": all_sources_cited,
            "source_count": len(source_surahs),
            "cited_count": len(cited_surahs),
            "uncited_sources": list(source_surahs - cited_surahs),
        }
    
    def detect_potential_hallucination(
        self,
        answer: str,
        sources: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Простая эвристика для определения возможных галлюцинаций.
        
        Проверяет:
        1. Наличие цифр/номеров, которых нет в источниках
        2. Специфические термины, которых нет в контексте
        3. Уверенные утверждения без источников
        """
        import re
        
        # Извлекаем весь текст из источников
        source_text = " ".join([s.get("text", "") for s in sources]).lower()
        answer_lower = answer.lower()
        
        # 1. Проверяем номера сур и аятов
        answer_numbers = set(re.findall(r'сура\s+(\d+)', answer_lower))
        source_numbers = set(re.findall(r'сура\s+(\d+)', source_text))
        
        hallucinated_numbers = answer_numbers - source_numbers
        
        # 2. Проверяем специфические исламские термины
        islamic_terms = [
            "харам", "халяль", "макрух", "мустахаб",
            "фард", "ваджиб", "суннат", "нафль"
        ]
        
        unsupported_terms = []
        for term in islamic_terms:
            if term in answer_lower and term not in source_text:
                unsupported_terms.append(term)
        
        # 3. Проверяем уверенные утверждения
        confident_phrases = [
            "точно", "определенно", "безусловно", "всегда",
            "никогда", "обязательно", "строго запрещено"
        ]
        
        has_confident_claims = any(phrase in answer_lower for phrase in confident_phrases)
        
        risk_score = 0
        if hallucinated_numbers:
            risk_score += len(hallucinated_numbers) * 2
        if unsupported_terms:
            risk_score += len(unsupported_terms)
        if has_confident_claims and not sources:
            risk_score += 3
        
        return {
            "risk_score": risk_score,
            "hallucinated_numbers": list(hallucinated_numbers),
            "unsupported_terms": unsupported_terms,
            "has_confident_claims": has_confident_claims,
            "likely_hallucination": risk_score > 3,
        }
    
    def get_quality_summary(self) -> Dict[str, Any]:
        """Возвращает сводку по качеству RAG."""
        if not self.feedback_data:
            return {"total_queries": 0}
        
        avg_docs = sum(d["num_docs"] for d in self.feedback_data) / len(self.feedback_data)
        avg_score = []
        for d in self.feedback_data:
            if d["doc_scores"]:
                avg_score.append(sum(d["doc_scores"]) / len(d["doc_scores"]))
        
        return {
            "total_queries": len(self.feedback_data),
            "avg_docs_retrieved": avg_docs,
            "avg_doc_score": sum(avg_score) / len(avg_score) if avg_score else 0,
        }


# Глобальный экземпляр монитора качества
quality_monitor = RAGQualityMonitor()


# Пример интеграции в FastAPI
"""
from fastapi import FastAPI

app = FastAPI()

@app.get("/metrics")
async def get_metrics():
    '''Endpoint для получения метрик.'''
    return metrics_collector.get_summary()

@app.get("/metrics/queries/recent")
async def get_recent_queries(limit: int = 10):
    '''Последние запросы.'''
    return metrics_collector.get_recent_queries(limit)

@app.get("/metrics/queries/failed")
async def get_failed_queries(limit: int = 10):
    '''Неудачные запросы.'''
    return metrics_collector.get_failed_queries(limit)

@app.get("/metrics/queries/slow")
async def get_slow_queries(threshold_ms: float = 5000, limit: int = 10):
    '''Медленные запросы.'''
    return metrics_collector.get_slow_queries(threshold_ms, limit)

@app.get("/metrics/rag/quality")
async def get_rag_quality():
    '''Метрики качества RAG.'''
    return quality_monitor.get_quality_summary()
"""
