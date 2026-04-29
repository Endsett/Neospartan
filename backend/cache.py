"""Redis caching utilities for NeoSpartan Backend."""

import json
import pickle
from typing import Any, Optional, Union
from functools import wraps
import hashlib

from config import settings

# Lazy import redis to avoid errors if not configured
try:
    import redis.asyncio as redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    redis = None


class CacheManager:
    """Manages Redis caching for the application."""
    
    def __init__(self):
        self._redis: Optional[Any] = None
        self._enabled = REDIS_AVAILABLE and settings.redis_url
    
    async def connect(self):
        """Connect to Redis."""
        if not self._enabled:
            return
        
        try:
            if redis:
                self._redis = await redis.from_url(
                    settings.redis_url,
                    encoding="utf-8",
                    decode_responses=True
                )
        except Exception as e:
            print(f"Redis connection failed: {e}")
            self._enabled = False
    
    async def disconnect(self):
        """Disconnect from Redis."""
        if self._redis:
            await self._redis.close()
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        if not self._enabled or not self._redis:
            return None
        
        try:
            value = await self._redis.get(key)
            if value:
                return json.loads(value)
        except Exception:
            pass
        return None
    
    async def set(
        self,
        key: str,
        value: Any,
        ttl: int = 300  # 5 minutes default
    ) -> bool:
        """Set value in cache with TTL."""
        if not self._enabled or not self._redis:
            return False
        
        try:
            serialized = json.dumps(value, default=str)
            await self._redis.setex(key, ttl, serialized)
            return True
        except Exception:
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete value from cache."""
        if not self._enabled or not self._redis:
            return False
        
        try:
            await self._redis.delete(key)
            return True
        except Exception:
            return False
    
    async def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern."""
        if not self._enabled or not self._redis:
            return 0
        
        try:
            keys = await self._redis.keys(pattern)
            if keys:
                return await self._redis.delete(*keys)
        except Exception:
            pass
        return 0
    
    def generate_key(self, prefix: str, *args, **kwargs) -> str:
        """Generate cache key from arguments."""
        key_data = f"{prefix}:{str(args)}:{str(kwargs)}"
        return hashlib.md5(key_data.encode()).hexdigest()


# Global cache manager instance
cache = CacheManager()


def cached(ttl: int = 300, key_prefix: str = "cache"):
    """Decorator to cache function results."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            cache_key = cache.generate_key(key_prefix, func.__name__, *args, **kwargs)
            
            # Try to get from cache
            cached_value = await cache.get(cache_key)
            if cached_value is not None:
                return cached_value
            
            # Execute function
            result = await func(*args, **kwargs)
            
            # Store in cache
            await cache.set(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator


def invalidate_cache(key_prefix: str):
    """Decorator to invalidate cache after function execution."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            result = await func(*args, **kwargs)
            
            # Invalidate matching cache keys
            pattern = f"{key_prefix}:*"
            await cache.delete_pattern(pattern)
            
            return result
        return wrapper
    return decorator


# Common cache TTLs
CACHE_TTL = {
    "short": 60,      # 1 minute
    "medium": 300,    # 5 minutes
    "long": 3600,     # 1 hour
    "day": 86400,     # 24 hours
}
