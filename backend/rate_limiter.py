"""Enhanced rate limiting with Redis and tiered limits."""

import time
from typing import Optional, Dict
from enum import Enum
from functools import wraps

from fastapi import Request, HTTPException
from config import settings

# Try to import Redis
try:
    import redis.asyncio as redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    redis = None


class RateLimitTier(Enum):
    """Rate limit tiers for different endpoint types."""
    PUBLIC = "public"           # 100 req/min
    AUTHENTICATED = "auth"      # 200 req/min
    AI_GENERATION = "ai"        # 20 req/min (expensive)
    ADMIN = "admin"            # 500 req/min
    WEBSOCKET = "ws"           # 60 connections/min


# Rate limit configurations (requests per window)
RATE_LIMITS = {
    RateLimitTier.PUBLIC: {"requests": 100, "window": 60},
    RateLimitTier.AUTHENTICATED: {"requests": 200, "window": 60},
    RateLimitTier.AI_GENERATION: {"requests": 20, "window": 60},
    RateLimitTier.ADMIN: {"requests": 500, "window": 60},
    RateLimitTier.WEBSOCKET: {"requests": 60, "window": 60},
}


class RateLimiter:
    """Advanced rate limiter with Redis backend."""
    
    def __init__(self):
        self._redis: Optional[Any] = None
        self._local_cache: Dict[str, list] = {}
        self._use_redis = REDIS_AVAILABLE and settings.redis_url
    
    async def connect(self):
        """Connect to Redis."""
        if self._use_redis and redis:
            try:
                self._redis = await redis.from_url(settings.redis_url)
            except Exception:
                self._use_redis = False
    
    async def is_allowed(
        self,
        key: str,
        tier: RateLimitTier = RateLimitTier.AUTHENTICATED
    ) -> tuple[bool, dict]:
        """
        Check if request is allowed.
        Returns (allowed, rate_limit_info)
        """
        limit_config = RATE_LIMITS[tier]
        max_requests = limit_config["requests"]
        window = limit_config["window"]
        
        now = time.time()
        
        if self._use_redis and self._redis:
            return await self._check_redis(key, max_requests, window, now)
        else:
            return self._check_local(key, max_requests, window, now)
    
    async def _check_redis(
        self,
        key: str,
        max_requests: int,
        window: int,
        now: float
    ) -> tuple[bool, dict]:
        """Check rate limit using Redis."""
        redis_key = f"rate_limit:{key}"
        
        try:
            # Use Redis sorted set for sliding window
            # Remove old entries
            cutoff = now - window
            await self._redis.zremrangebyscore(redis_key, 0, cutoff)
            
            # Count current requests
            current_count = await self._redis.zcard(redis_key)
            
            # Add current request
            await self._redis.zadd(redis_key, {str(now): now})
            
            # Set expiration
            await self._redis.expire(redis_key, window)
            
            remaining = max(0, max_requests - current_count - 1)
            reset_time = int(now + window)
            
            allowed = current_count < max_requests
            
            info = {
                "limit": max_requests,
                "remaining": remaining,
                "reset": reset_time,
                "window": window,
            }
            
            return allowed, info
            
        except Exception:
            # Fall back to local if Redis fails
            return self._check_local(key, max_requests, window, now)
    
    def _check_local(
        self,
        key: str,
        max_requests: int,
        window: int,
        now: float
    ) -> tuple[bool, dict]:
        """Check rate limit using local memory."""
        if key not in self._local_cache:
            self._local_cache[key] = []
        
        # Remove old requests
        cutoff = now - window
        self._local_cache[key] = [
            t for t in self._local_cache[key] if t > cutoff
        ]
        
        current_count = len(self._local_cache[key])
        
        # Add current request
        self._local_cache[key].append(now)
        
        remaining = max(0, max_requests - current_count - 1)
        reset_time = int(now + window)
        
        allowed = current_count < max_requests
        
        info = {
            "limit": max_requests,
            "remaining": remaining,
            "reset": reset_time,
            "window": window,
        }
        
        return allowed, info
    
    async def get_rate_limit_info(
        self,
        key: str,
        tier: RateLimitTier = RateLimitTier.AUTHENTICATED
    ) -> dict:
        """Get current rate limit info without consuming a request."""
        limit_config = RATE_LIMITS[tier]
        max_requests = limit_config["requests"]
        window = limit_config["window"]
        
        now = time.time()
        
        if self._use_redis and self._redis:
            redis_key = f"rate_limit:{key}"
            try:
                cutoff = now - window
                current_count = await self._redis.zcount(redis_key, cutoff, now)
                remaining = max(0, max_requests - current_count)
                
                return {
                    "limit": max_requests,
                    "remaining": remaining,
                    "reset": int(now + window),
                    "window": window,
                }
            except Exception:
                pass
        
        # Local fallback
        if key in self._local_cache:
            cutoff = now - window
            current_count = len([t for t in self._local_cache[key] if t > cutoff])
            remaining = max(0, max_requests - current_count)
        else:
            remaining = max_requests
        
        return {
            "limit": max_requests,
            "remaining": remaining,
            "reset": int(now + window),
            "window": window,
        }


# Global rate limiter instance
rate_limiter = RateLimiter()


def rate_limit(tier: RateLimitTier = RateLimitTier.AUTHENTICATED):
    """
    Decorator to apply rate limiting to an endpoint.
    
    Usage:
        @app.get("/api/data")
        @rate_limit(tier=RateLimitTier.AUTHENTICATED)
        async def get_data():
            return {"data": "value"}
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Extract request from args/kwargs
            request: Optional[Request] = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            
            if not request:
                for value in kwargs.values():
                    if isinstance(value, Request):
                        request = value
                        break
            
            if request:
                # Create unique key
                client_ip = request.client.host if request.client else "unknown"
                user_id = getattr(request.state, "user_id", None)
                
                if user_id:
                    key = f"user:{user_id}"
                else:
                    key = f"ip:{client_ip}"
                
                # Check rate limit
                allowed, info = await rate_limiter.is_allowed(key, tier)
                
                if not allowed:
                    raise HTTPException(
                        status_code=429,
                        detail="Rate limit exceeded",
                        headers={
                            "X-RateLimit-Limit": str(info["limit"]),
                            "X-RateLimit-Remaining": "0",
                            "X-RateLimit-Reset": str(info["reset"]),
                            "Retry-After": str(info["window"]),
                        }
                    )
                
                # Store rate limit info in request state
                request.state.rate_limit_info = info
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator


# Convenience decorators for common tiers
def public_rate_limit(func):
    """Apply public tier rate limit."""
    return rate_limit(RateLimitTier.PUBLIC)(func)

def auth_rate_limit(func):
    """Apply authenticated tier rate limit."""
    return rate_limit(RateLimitTier.AUTHENTICATED)(func)

def ai_rate_limit(func):
    """Apply AI generation tier rate limit."""
    return rate_limit(RateLimitTier.AI_GENERATION)(func)

def admin_rate_limit(func):
    """Apply admin tier rate limit."""
    return rate_limit(RateLimitTier.ADMIN)(func)
