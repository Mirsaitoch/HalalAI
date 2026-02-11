"""
Улучшения производительности для LLM сервиса.

Включает:
1. Батчинг запросов для эффективной обработки
2. Streaming responses для улучшения UX
3. Rate limiting для защиты от перегрузки
4. Connection pooling для БД и внешних API
5. Асинхронная обработка
"""

import asyncio
from typing import Any, AsyncGenerator, Dict, List, Optional
from datetime import datetime, timedelta
from collections import deque
import time
import logging

logger = logging.getLogger(__name__)


class RequestBatcher:
    """
    Батчер для группировки запросов и их эффективной обработки.
    
    Полезно для:
    - Группировки embedding запросов
    - Батчинг inference для локальной модели
    """
    
    def __init__(
        self,
        max_batch_size: int = 8,
        max_wait_ms: float = 50,
    ):
        self.max_batch_size = max_batch_size
        self.max_wait_ms = max_wait_ms
        self.pending_requests: List[Dict[str, Any]] = []
        self.lock = asyncio.Lock()
        
    async def add_request(
        self,
        request_id: str,
        data: Any,
    ) -> Any:
        """
        Добавляет запрос в батч и ждет результат.
        
        Args:
            request_id: Уникальный ID запроса
            data: Данные запроса
            
        Returns:
            Результат обработки
        """
        future = asyncio.Future()
        
        async with self.lock:
            self.pending_requests.append({
                "id": request_id,
                "data": data,
                "future": future,
                "timestamp": time.time(),
            })
            
            # Если набрали полный батч, обрабатываем немедленно
            if len(self.pending_requests) >= self.max_batch_size:
                asyncio.create_task(self._process_batch())
        
        # Ждем результат
        return await future
    
    async def _process_batch(self):
        """Обрабатывает батч запросов."""
        async with self.lock:
            if not self.pending_requests:
                return
            
            batch = self.pending_requests[:]
            self.pending_requests.clear()
        
        try:
            # Здесь реальная обработка батча
            results = await self._batch_process([r["data"] for r in batch])
            
            # Возвращаем результаты
            for request, result in zip(batch, results):
                request["future"].set_result(result)
        
        except Exception as e:
            logger.error(f"Ошибка при обработке батча: {e}")
            for request in batch:
                request["future"].set_exception(e)
    
    async def _batch_process(self, data_batch: List[Any]) -> List[Any]:
        """
        Обрабатывает батч данных.
        Переопределите этот метод для конкретной логики.
        """
        # Пример: батчинг embeddings
        # embeddings = self.embedder.encode(data_batch, convert_to_tensor=True)
        # return embeddings
        
        await asyncio.sleep(0.01)  # Симуляция обработки
        return data_batch


class StreamingResponse:
    """
    Генератор для streaming ответов от LLM.
    
    Улучшает UX, показывая ответ по мере генерации.
    """
    
    @staticmethod
    async def stream_tokens(
        model,
        tokenizer,
        prompt: str,
        max_tokens: int = 1024,
    ) -> AsyncGenerator[str, None]:
        """
        Стримит токены по мере генерации.
        
        Args:
            model: LLM модель
            tokenizer: Токенизатор
            prompt: Промпт для генерации
            max_tokens: Максимальное количество токенов
            
        Yields:
            Сгенерированные токены
        """
        # Подготовка входа
        inputs = tokenizer([prompt], return_tensors="pt").to(model.device)
        
        # Streaming генерация
        streamer_kwargs = {
            "max_new_tokens": max_tokens,
            "do_sample": True,
            "temperature": 0.4,
            "top_p": 0.85,
        }
        
        # Используем TextIteratorStreamer из transformers
        from transformers import TextIteratorStreamer
        import threading
        
        streamer = TextIteratorStreamer(tokenizer, skip_special_tokens=True)
        
        # Запускаем генерацию в отдельном потоке
        generation_kwargs = dict(inputs, streamer=streamer, **streamer_kwargs)
        thread = threading.Thread(target=model.generate, kwargs=generation_kwargs)
        thread.start()
        
        # Стримим токены
        for text in streamer:
            yield text
            await asyncio.sleep(0)  # Даем другим задачам выполниться
        
        thread.join()


class RateLimiter:
    """
    Rate limiter для защиты от перегрузки.
    
    Реализует алгоритм Token Bucket.
    """
    
    def __init__(
        self,
        rate: int = 10,  # запросов в секунду
        burst: int = 20,  # максимальный burst
    ):
        self.rate = rate
        self.burst = burst
        self.tokens = burst
        self.last_update = time.time()
        self.lock = asyncio.Lock()
        
    async def acquire(self, client_id: str = "default") -> bool:
        """
        Пытается получить токен для выполнения запроса.
        
        Args:
            client_id: Идентификатор клиента (для per-client limiting)
            
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
    
    async def wait_for_token(self, client_id: str = "default", timeout: float = 30):
        """
        Ждет доступности токена с таймаутом.
        
        Args:
            client_id: Идентификатор клиента
            timeout: Максимальное время ожидания
            
        Raises:
            TimeoutError: Если не удалось получить токен за timeout
        """
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            if await self.acquire(client_id):
                return
            await asyncio.sleep(0.1)
        
        raise TimeoutError(f"Rate limit timeout for client {client_id}")


class AdvancedRateLimiter:
    """
    Продвинутый rate limiter с поддержкой нескольких клиентов.
    """
    
    def __init__(
        self,
        default_rate: int = 10,
        default_burst: int = 20,
    ):
        self.default_rate = default_rate
        self.default_burst = default_burst
        self.limiters: Dict[str, RateLimiter] = {}
        self.lock = asyncio.Lock()
        
    async def acquire(
        self,
        client_id: str,
        custom_rate: Optional[int] = None,
    ) -> bool:
        """Получает токен для клиента."""
        async with self.lock:
            if client_id not in self.limiters:
                rate = custom_rate or self.default_rate
                self.limiters[client_id] = RateLimiter(rate=rate, burst=rate * 2)
        
        return await self.limiters[client_id].acquire(client_id)
    
    def get_client_stats(self, client_id: str) -> Dict[str, Any]:
        """Возвращает статистику по клиенту."""
        if client_id not in self.limiters:
            return {"client_id": client_id, "exists": False}
        
        limiter = self.limiters[client_id]
        return {
            "client_id": client_id,
            "exists": True,
            "rate": limiter.rate,
            "burst": limiter.burst,
            "available_tokens": limiter.tokens,
        }


class ConnectionPool:
    """
    Пул соединений для переиспользования HTTP клиентов.
    
    Избегает накладных расходов на создание новых соединений.
    """
    
    def __init__(self, max_connections: int = 100):
        self.max_connections = max_connections
        self.sessions = {}
        
    async def get_session(self, base_url: str):
        """
        Получает или создает HTTP сессию для base_url.
        
        В production используйте httpx.AsyncClient с connection pooling.
        """
        import httpx
        
        if base_url not in self.sessions:
            self.sessions[base_url] = httpx.AsyncClient(
                base_url=base_url,
                timeout=30.0,
                limits=httpx.Limits(
                    max_connections=self.max_connections,
                    max_keepalive_connections=20,
                ),
            )
        
        return self.sessions[base_url]
    
    async def close_all(self):
        """Закрывает все соединения."""
        for session in self.sessions.values():
            await session.aclose()
        self.sessions.clear()


class CacheWarmer:
    """
    Прогревает кэш популярными запросами при старте.
    """
    
    def __init__(self, rag_pipeline, cache):
        self.rag_pipeline = rag_pipeline
        self.cache = cache
        
    async def warm_cache(self, common_queries: List[str]):
        """
        Прогревает кэш частыми запросами.
        
        Args:
            common_queries: Список популярных запросов
        """
        logger.info(f"Прогреваем кэш для {len(common_queries)} запросов...")
        
        tasks = []
        for query in common_queries:
            task = self._warm_single_query(query)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        success_count = sum(1 for r in results if not isinstance(r, Exception))
        logger.info(f"Кэш прогрет: {success_count}/{len(common_queries)} успешно")
    
    async def _warm_single_query(self, query: str):
        """Прогревает кэш для одного запроса."""
        try:
            # Выполняем RAG поиск
            results = await asyncio.to_thread(
                self.rag_pipeline.retrieve,
                query,
                top_k=3,
            )
            
            # Сохраняем в кэш
            self.cache.set(query, results)
            
            return True
        except Exception as e:
            logger.error(f"Ошибка при прогреве кэша для '{query}': {e}")
            return False
    
    @staticmethod
    def get_common_islamic_queries() -> List[str]:
        """Возвращает список популярных исламских запросов."""
        return [
            "Что говорится о свинине в Коране?",
            "Как совершать намаз?",
            "Что такое закят?",
            "Когда начинается Рамадан?",
            "Можно ли есть морепродукты?",
            "Что говорится об алкоголе?",
            "Как делать тахарат?",
            "Сколько раз в день нужно молиться?",
            "Что такое хадж?",
            "Обязательно ли носить хиджаб?",
            "Можно ли есть в пост?",
            "Что значит халяль?",
            "Что такое харам?",
            "Как правильно читать Коран?",
            "Что говорится о благотворительности?",
        ]


class BackgroundTaskManager:
    """
    Менеджер для фоновых задач.
    
    Полезно для:
    - Периодической очистки кэша
    - Обновления индекса
    - Сбора метрик
    """
    
    def __init__(self):
        self.tasks: List[asyncio.Task] = []
        self.running = False
        
    async def start(self):
        """Запускает фоновые задачи."""
        self.running = True
        
        # Запускаем задачи
        self.tasks.append(asyncio.create_task(self._cleanup_cache()))
        self.tasks.append(asyncio.create_task(self._log_metrics()))
        
        logger.info("Фоновые задачи запущены")
    
    async def stop(self):
        """Останавливает фоновые задачи."""
        self.running = False
        
        for task in self.tasks:
            task.cancel()
        
        await asyncio.gather(*self.tasks, return_exceptions=True)
        logger.info("Фоновые задачи остановлены")
    
    async def _cleanup_cache(self):
        """Периодически очищает устаревший кэш."""
        while self.running:
            try:
                await asyncio.sleep(3600)  # Каждый час
                # Здесь логика очистки кэша
                logger.info("Выполнена очистка кэша")
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Ошибка при очистке кэша: {e}")
    
    async def _log_metrics(self):
        """Периодически логирует метрики."""
        while self.running:
            try:
                await asyncio.sleep(300)  # Каждые 5 минут
                # Здесь логика сбора и отправки метрик
                logger.info("Метрики собраны и отправлены")
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Ошибка при сборе метрик: {e}")


# Пример интеграции в FastAPI
"""
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import StreamingResponse

app = FastAPI()

# Инициализация компонентов
rate_limiter = AdvancedRateLimiter(default_rate=10)
connection_pool = ConnectionPool()
background_tasks = BackgroundTaskManager()

@app.on_event("startup")
async def startup():
    await background_tasks.start()
    
    # Прогрев кэша
    cache_warmer = CacheWarmer(rag_pipeline, query_cache)
    common_queries = CacheWarmer.get_common_islamic_queries()
    await cache_warmer.warm_cache(common_queries)

@app.on_event("shutdown")
async def shutdown():
    await background_tasks.stop()
    await connection_pool.close_all()

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    '''Rate limiting middleware.'''
    client_id = request.client.host
    
    if not await rate_limiter.acquire(client_id):
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Please try again later."
        )
    
    response = await call_next(request)
    return response

@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    '''Streaming endpoint для чата.'''
    
    async def generate():
        async for token in StreamingResponse.stream_tokens(
            model=local_llm.model,
            tokenizer=local_llm.tokenizer,
            prompt=request.prompt,
            max_tokens=request.max_tokens or 1024,
        ):
            yield f"data: {token}\n\n"
    
    return StreamingResponse(
        generate(),
        media_type="text/event-stream"
    )
"""
