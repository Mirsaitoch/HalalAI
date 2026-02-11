"""Тесты для rate limiter."""

import asyncio
import pytest

from halal_ai.api.middleware.rate_limiter import RateLimiter, TokenBucket


class TestTokenBucket:
    """Тесты для Token Bucket алгоритма."""
    
    @pytest.mark.asyncio
    async def test_initial_tokens(self):
        """Проверяет начальное количество токенов."""
        bucket = TokenBucket(rate=10.0, burst=20)
        
        assert bucket.tokens == 20.0
        assert bucket.rate == 10.0
        assert bucket.burst == 20
    
    @pytest.mark.asyncio
    async def test_acquire_token(self):
        """Проверяет получение токена."""
        bucket = TokenBucket(rate=10.0, burst=20)
        
        # Первый запрос должен пройти
        allowed = await bucket.acquire()
        assert allowed is True
        assert bucket.tokens == 19.0
    
    @pytest.mark.asyncio
    async def test_burst_limit(self):
        """Проверяет ограничение burst."""
        bucket = TokenBucket(rate=10.0, burst=3)
        
        # Первые 3 запроса должны пройти (burst)
        for i in range(3):
            allowed = await bucket.acquire()
            assert allowed is True, f"Request {i+1} should be allowed"
        
        # 4-й запрос должен быть заблокирован
        allowed = await bucket.acquire()
        assert allowed is False
    
    @pytest.mark.asyncio
    async def test_token_refill(self):
        """Проверяет пополнение токенов со временем."""
        bucket = TokenBucket(rate=10.0, burst=1)  # 10 токенов в секунду
        
        # Используем единственный токен
        await bucket.acquire()
        assert bucket.tokens < 1.0
        
        # Ждем 0.15 секунды (должно появиться ~1.5 токена)
        await asyncio.sleep(0.15)
        
        # Должен появиться новый токен
        allowed = await bucket.acquire()
        assert allowed is True
    
    @pytest.mark.asyncio
    async def test_get_wait_time(self):
        """Проверяет вычисление времени ожидания."""
        bucket = TokenBucket(rate=10.0, burst=1)
        
        # Есть токены - ждать не нужно
        wait_time = bucket.get_wait_time()
        assert wait_time == 0.0
        
        # Используем токен
        await bucket.acquire()
        
        # Теперь нужно ждать
        wait_time = bucket.get_wait_time()
        assert wait_time > 0.0
        assert wait_time <= 0.1  # При rate=10, макс 0.1 сек


class TestRateLimiter:
    """Тесты для Rate Limiter."""
    
    @pytest.mark.asyncio
    async def test_different_clients(self):
        """Проверяет раздельные лимиты для разных клиентов."""
        limiter = RateLimiter(default_rate=10.0, default_burst=2)
        
        # Клиент A использует свой лимит
        assert await limiter.acquire("client_a") is True
        assert await limiter.acquire("client_a") is True
        assert await limiter.acquire("client_a") is False  # Превышен лимит
        
        # Клиент B должен иметь свой независимый лимит
        assert await limiter.acquire("client_b") is True
        assert await limiter.acquire("client_b") is True
        assert await limiter.acquire("client_b") is False
    
    @pytest.mark.asyncio
    async def test_bucket_creation(self):
        """Проверяет создание buckets для новых клиентов."""
        limiter = RateLimiter(default_rate=10.0, default_burst=5)
        
        # Изначально нет buckets
        assert len(limiter.buckets) == 0
        
        # После первого запроса создается bucket
        await limiter.acquire("client_1")
        assert len(limiter.buckets) == 1
        assert "client_1" in limiter.buckets
        
        # Второй клиент создает свой bucket
        await limiter.acquire("client_2")
        assert len(limiter.buckets) == 2
    
    @pytest.mark.asyncio
    async def test_get_stats(self):
        """Проверяет получение статистики."""
        limiter = RateLimiter(default_rate=5.0, default_burst=10)
        
        await limiter.acquire("client_1")
        await limiter.acquire("client_2")
        
        stats = limiter.get_stats()
        
        assert stats["active_clients"] == 2
        assert stats["default_rate"] == 5.0
        assert stats["default_burst"] == 10
    
    @pytest.mark.asyncio
    async def test_rate_limit_recovery(self):
        """Проверяет восстановление после превышения лимита."""
        limiter = RateLimiter(default_rate=10.0, default_burst=1)
        
        # Используем токен
        assert await limiter.acquire("client") is True
        
        # Превышаем лимит
        assert await limiter.acquire("client") is False
        
        # Ждем восстановления
        await asyncio.sleep(0.15)
        
        # Должен появиться новый токен
        assert await limiter.acquire("client") is True


@pytest.mark.asyncio
async def test_concurrent_requests():
    """Проверяет корректную работу при конкурентных запросах."""
    limiter = RateLimiter(default_rate=10.0, default_burst=5)
    
    # Запускаем 10 параллельных запросов
    tasks = [limiter.acquire("client") for _ in range(10)]
    results = await asyncio.gather(*tasks)
    
    # Должны пройти только первые 5 (burst limit)
    allowed_count = sum(1 for r in results if r)
    assert allowed_count == 5
    
    denied_count = sum(1 for r in results if not r)
    assert denied_count == 5
