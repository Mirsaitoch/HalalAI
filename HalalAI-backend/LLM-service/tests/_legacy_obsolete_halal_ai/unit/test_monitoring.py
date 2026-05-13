"""Тесты для системы мониторинга и метрик."""

import pytest

from halal_ai.services.monitoring.metrics import MetricsCollector


class TestMetricsCollector:
    """Тесты для сборщика метрик."""
    
    @pytest.fixture
    def collector(self):
        """Создает новый коллектор метрик для каждого теста."""
        collector = MetricsCollector(max_history=100)
        collector.reset()
        return collector
    
    def test_initial_state(self, collector):
        """Проверяет начальное состояние коллектора."""
        assert collector.total_requests == 0
        assert collector.successful_requests == 0
        assert collector.failed_requests == 0
        assert collector.rag_queries == 0
    
    def test_record_successful_request(self, collector):
        """Проверяет запись успешного запроса."""
        collector.record_request(
            success=True,
            latency_ms=100.0,
            used_rag=True,
            query="Test query"
        )
        
        assert collector.total_requests == 1
        assert collector.successful_requests == 1
        assert collector.failed_requests == 0
        assert len(collector.recent_queries) == 1
    
    def test_record_failed_request(self, collector):
        """Проверяет запись неудачного запроса."""
        collector.record_request(
            success=False,
            latency_ms=50.0,
            error="Test error"
        )
        
        assert collector.total_requests == 1
        assert collector.successful_requests == 0
        assert collector.failed_requests == 1
    
    def test_record_rag_search(self, collector):
        """Проверяет запись метрик RAG поиска."""
        collector.record_rag_search(
            latency_ms=200.0,
            results_count=3,
            avg_score=0.85
        )
        
        assert collector.rag_queries == 1
        assert len(collector.rag_scores) == 1
        assert collector.rag_scores[0] == 0.85
    
    def test_record_rag_empty_results(self, collector):
        """Проверяет запись пустых результатов RAG."""
        collector.record_rag_search(
            latency_ms=150.0,
            results_count=0
        )
        
        assert collector.rag_empty_results == 1
    
    def test_get_summary(self, collector):
        """Проверяет получение сводки метрик."""
        # Записываем несколько запросов
        collector.record_request(success=True, latency_ms=100.0)
        collector.record_request(success=True, latency_ms=200.0)
        collector.record_request(success=False, latency_ms=50.0)
        
        summary = collector.get_summary()
        
        assert summary["requests"]["total"] == 3
        assert summary["requests"]["successful"] == 2
        assert summary["requests"]["failed"] == 1
        assert summary["requests"]["success_rate"] == pytest.approx(2/3, 0.01)
    
    def test_get_recent_queries(self, collector):
        """Проверяет получение последних запросов."""
        # Записываем 5 запросов
        for i in range(5):
            collector.record_request(
                success=True,
                latency_ms=100.0,
                query=f"Query {i}"
            )
        
        recent = collector.get_recent_queries(limit=3)
        
        assert len(recent) == 3
        assert recent[-1]["query"] == "Query 4"
    
    def test_get_failed_queries(self, collector):
        """Проверяет получение неудачных запросов."""
        collector.record_request(success=True, latency_ms=100.0, query="Success 1")
        collector.record_request(success=False, latency_ms=50.0, query="Failed 1", error="Error 1")
        collector.record_request(success=True, latency_ms=100.0, query="Success 2")
        collector.record_request(success=False, latency_ms=60.0, query="Failed 2", error="Error 2")
        
        failed = collector.get_failed_queries()
        
        assert len(failed) == 2
        assert all(not q["success"] for q in failed)
        assert failed[0]["query"] == "Failed 1"
        assert failed[1]["query"] == "Failed 2"
    
    def test_get_slow_queries(self, collector):
        """Проверяет получение медленных запросов."""
        collector.record_request(success=True, latency_ms=1000.0, query="Fast")
        collector.record_request(success=True, latency_ms=6000.0, query="Slow 1")
        collector.record_request(success=True, latency_ms=8000.0, query="Slow 2")
        
        slow = collector.get_slow_queries(threshold_ms=5000.0, limit=10)
        
        assert len(slow) == 2
        # Должны быть отсортированы по латентности (убывание)
        assert slow[0]["query"] == "Slow 2"
        assert slow[1]["query"] == "Slow 1"
    
    def test_percentile_calculation(self, collector):
        """Проверяет вычисление перцентилей."""
        # Записываем запросы с известными латентностями
        latencies = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
        for lat in latencies:
            collector.record_request(success=True, latency_ms=float(lat))
        
        summary = collector.get_summary()
        
        # P50 должен быть около 500-600
        assert 500 <= summary["latency"]["request_p50_ms"] <= 600
        
        # P95 должен быть около 950-1000
        assert 900 <= summary["latency"]["request_p95_ms"] <= 1000
    
    def test_reset(self, collector):
        """Проверяет сброс всех метрик."""
        collector.record_request(success=True, latency_ms=100.0)
        collector.record_rag_search(latency_ms=50.0, results_count=3)
        
        assert collector.total_requests > 0
        assert collector.rag_queries > 0
        
        collector.reset()
        
        assert collector.total_requests == 0
        assert collector.rag_queries == 0
        assert len(collector.recent_queries) == 0
    
    def test_history_limit(self, collector):
        """Проверяет ограничение размера истории."""
        collector_small = MetricsCollector(max_history=5)
        
        # Записываем 10 запросов
        for i in range(10):
            collector_small.record_request(
                success=True,
                latency_ms=100.0,
                query=f"Query {i}"
            )
        
        # Должно быть только последние 5
        assert len(collector_small.recent_queries) == 5
        assert collector_small.recent_queries[-1]["query"] == "Query 9"
