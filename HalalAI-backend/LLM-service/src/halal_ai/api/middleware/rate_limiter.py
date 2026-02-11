"""Rate limiting middleware для защиты от перегрузки."""

import asyncio
import logging
import time
from typing import Callable, Dict, Optional

from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class TokenBucket:
    """
    Реализация алгоритма Token Bucket для rate limiting.
    
    Позволяет короткие всплески активности, но ограничивает средний rate.
    """
    
    def __init__(self, rate: float, burst: int):
        """
        Инициализирует bucket.
        
        Args:
            rate: Скорость пополнения токенов (запросов в секунду)
            burst: Максимальное количество токенов (burst capacity)
        """
        self.rate = rate
        self.burst = burst
        self.tokens = float(burst)
        self.last_update = time.time()
        self.lock = asyncio.Lock()
    
    async def acquire(self) -> bool:
        """
        Пытается получить токен для выполнения запроса.
        
        Returns:
            True если запрос разрешен, False если превышен лимит
        """
        async with self.lock:
            now = time.time()
            elapsed = now - self.last_update
            
            # Добавляем токены за прошедшее время
            self.tokens = min(
                self.burst,
                self.tokens + elapsed * self.rate
            )
            self.last_update = now
            
            # Проверяем доступность токена
            if self.tokens >= 1:
                self.tokens -= 1
                return True
            else:
                return False
    
    def get_wait_time(self) -> float:
        """
        Возвращает время ожидания до появления следующего токена (в секундах).
        
        Returns:
            Время ожидания в секундах
        """
        if self.tokens >= 1:
            return 0.0
        return (1 - self.tokens) / self.rate


class RateLimiter:
    """
    Rate limiter с поддержкой нескольких клиентов.
    
    Использует IP адрес клиента как идентификатор.
    """
    
    def __init__(
        self,
        default_rate: float = 10.0,  # 10 requests/second
        default_burst: int = 20,      # burst до 20
    ):
        """
        Инициализирует rate limiter.
        
        Args:
            default_rate: Скорость по умолчанию (запросов в секунду)
            default_burst: Burst по умолчанию
        """
        self.default_rate = default_rate
        self.default_burst = default_burst
        self.buckets: Dict[str, TokenBucket] = {}
        self.cleanup_interval = 300  # Очищаем старые buckets каждые 5 минут
        self.last_cleanup = time.time()
    
    async def acquire(self, client_id: str) -> bool:
        """
        Пытается получить разрешение на запрос для клиента.
        
        Args:
            client_id: Идентификатор клиента (обычно IP адрес)
            
        Returns:
            True если запрос разрешен, False если превышен лимит
        """
        # Периодически очищаем старые buckets
        if time.time() - self.last_cleanup > self.cleanup_interval:
            await self._cleanup_old_buckets()
        
        # Получаем или создаем bucket для клиента
        if client_id not in self.buckets:
            self.buckets[client_id] = TokenBucket(
                rate=self.default_rate,
                burst=self.default_burst
            )
        
        return await self.buckets[client_id].acquire()
    
    async def _cleanup_old_buckets(self) -> None:
        """Очищает buckets для неактивных клиентов."""
        now = time.time()
        inactive_clients = [
            client_id for client_id, bucket in self.buckets.items()
            if now - bucket.last_update > 3600  # Неактивны более часа
        ]
        
        for client_id in inactive_clients:
            del self.buckets[client_id]
        
        if inactive_clients:
            logger.info("Очищено %d неактивных rate limit buckets", len(inactive_clients))
        
        self.last_cleanup = now
    
    def get_stats(self) -> Dict[str, any]:
        """
        Возвращает статистику rate limiter.
        
        Returns:
            Словарь со статистикой
        """
        return {
            "active_clients": len(self.buckets),
            "default_rate": self.default_rate,
            "default_burst": self.default_burst,
        }


# Глобальный экземпляр rate limiter
rate_limiter = RateLimiter(
    default_rate=10.0,   # 10 запросов/сек по умолчанию
    default_burst=20,    # с burst до 20
)


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Middleware для FastAPI, применяющий rate limiting ко всем запросам.
    
    Исключения:
    - /health - проверка здоровья
    - /docs, /redoc, /openapi.json - документация
    - /metrics - мониторинг
    """
    
    # Эндпоинты, которые не подлежат rate limiting
    EXCLUDED_PATHS = {"/health", "/docs", "/redoc", "/openapi.json"}
    
    def __init__(
        self,
        app,
        rate_limiter: RateLimiter,
        enabled: bool = True,
    ):
        """
        Инициализирует middleware.
        
        Args:
            app: FastAPI приложение
            rate_limiter: Экземпляр RateLimiter
            enabled: Включен ли rate limiting (можно отключить для тестов)
        """
        super().__init__(app)
        self.rate_limiter = rate_limiter
        self.enabled = enabled
    
    async def dispatch(
        self,
        request: Request,
        call_next: Callable,
    ) -> Response:
        """
        Обрабатывает запрос с проверкой rate limit.
        
        Args:
            request: HTTP запрос
            call_next: Следующий обработчик
            
        Returns:
            HTTP ответ
        """
        # Проверяем, нужно ли применять rate limiting
        if not self.enabled or self._is_excluded(request.url.path):
            return await call_next(request)
        
        # Получаем идентификатор клиента (IP адрес)
        client_id = self._get_client_id(request)
        
        # Проверяем rate limit
        allowed = await self.rate_limiter.acquire(client_id)
        
        if not allowed:
            logger.warning(
                "Rate limit exceeded for client %s, path %s",
                client_id,
                request.url.path
            )
            return JSONResponse(
                status_code=429,
                content={
                    "error": {
                        "code": "RATE_LIMIT_EXCEEDED",
                        "message": "Too many requests. Please try again later.",
                        "details": {
                            "rate_limit": f"{self.rate_limiter.default_rate} requests/sec",
                            "burst": self.rate_limiter.default_burst,
                        }
                    }
                },
                headers={
                    "Retry-After": "1",  # Повторить через 1 секунду
                    "X-RateLimit-Limit": str(self.rate_limiter.default_burst),
                    "X-RateLimit-Remaining": "0",
                }
            )
        
        # Выполняем запрос
        response = await call_next(request)
        
        # Добавляем заголовки rate limit в ответ
        response.headers["X-RateLimit-Limit"] = str(self.rate_limiter.default_burst)
        
        return response
    
    @staticmethod
    def _get_client_id(request: Request) -> str:
        """
        Извлекает идентификатор клиента из запроса.
        
        Args:
            request: HTTP запрос
            
        Returns:
            Идентификатор клиента (IP адрес)
        """
        # Проверяем заголовок X-Forwarded-For (за прокси/load balancer)
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            # Берем первый IP (реальный клиент)
            return forwarded.split(",")[0].strip()
        
        # Иначе используем client.host
        if request.client:
            return request.client.host
        
        return "unknown"
    
    @staticmethod
    def _is_excluded(path: str) -> bool:
        """
        Проверяет, исключен ли путь из rate limiting.
        
        Args:
            path: Путь запроса
            
        Returns:
            True если путь исключен
        """
        return path in RateLimitMiddleware.EXCLUDED_PATHS or path.startswith("/metrics")
