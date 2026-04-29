"""Custom middleware for NeoSpartan Backend."""

import time
import uuid
from typing import Optional

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from cache import cache
from logging_config import get_logger

logger = get_logger("middleware")


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Add unique request ID to each request for tracing."""
    
    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        # Add request ID to headers
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        
        return response


class TimingMiddleware(BaseHTTPMiddleware):
    """Track request timing and log slow requests."""
    
    def __init__(self, app: ASGIApp, slow_threshold: float = 1.0):
        super().__init__(app)
        self.slow_threshold = slow_threshold
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        response = await call_next(request)
        
        process_time = time.time() - start_time
        
        # Add timing header
        response.headers["X-Process-Time"] = str(process_time)
        
        # Log slow requests
        if process_time > self.slow_threshold:
            logger.warning(
                f"Slow request: {request.method} {request.url.path} "
                f"took {process_time:.2f}s",
                extra={
                    "request_id": getattr(request.state, "request_id", None),
                    "duration": process_time,
                    "path": request.url.path,
                    "method": request.method,
                }
            )
        
        return response


class ErrorHandlingMiddleware(BaseHTTPMiddleware):
    """Global error handling middleware."""
    
    async def dispatch(self, request: Request, call_next):
        try:
            return await call_next(request)
        except Exception as e:
            logger.error(
                f"Unhandled exception: {str(e)}",
                extra={
                    "request_id": getattr(request.state, "request_id", None),
                    "path": request.url.path,
                    "method": request.method,
                },
                exc_info=True
            )
            
            # Return generic error response
            from fastapi.responses import JSONResponse
            return JSONResponse(
                status_code=500,
                content={
                    "error": "Internal server error",
                    "request_id": getattr(request.state, "request_id", None),
                }
            )


class CacheMiddleware(BaseHTTPMiddleware):
    """Simple response caching middleware for GET requests."""
    
    def __init__(
        self,
        app: ASGIApp,
        ttl: int = 300,
        exclude_paths: Optional[list] = None
    ):
        super().__init__(app)
        self.ttl = ttl
        self.exclude_paths = exclude_paths or ["/health", "/health/detailed"]
    
    async def dispatch(self, request: Request, call_next):
        # Only cache GET requests
        if request.method != "GET":
            return await call_next(request)
        
        # Skip excluded paths
        path = request.url.path
        if any(excluded in path for excluded in self.exclude_paths):
            return await call_next(request)
        
        # Skip authenticated requests
        if "authorization" in request.headers:
            return await call_next(request)
        
        # Generate cache key
        cache_key = f"cache:{path}:{str(request.query_params)}"
        
        # Try to get from cache
        cached_response = await cache.get(cache_key)
        if cached_response:
            from fastapi.responses import JSONResponse
            return JSONResponse(
                content=cached_response["body"],
                status_code=cached_response["status_code"],
                headers=cached_response.get("headers", {})
            )
        
        # Execute request
        response = await call_next(request)
        
        # Cache successful responses
        if response.status_code == 200:
            # We need to read and re-create the response body
            # This is simplified - real implementation would need proper body handling
            pass
        
        return response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add security headers to all responses."""
    
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        
        # Security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        
        return response
