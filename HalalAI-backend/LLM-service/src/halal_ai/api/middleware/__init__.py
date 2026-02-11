"""Middleware для FastAPI приложения."""

from halal_ai.api.middleware.rate_limiter import RateLimitMiddleware, rate_limiter

__all__ = ["RateLimitMiddleware", "rate_limiter"]
