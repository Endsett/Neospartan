"""Supabase database client for NeoSpartan Backend."""

from typing import Optional, Dict, Any, List
from functools import lru_cache

from supabase import create_client, Client
from postgrest.exceptions import APIError

from config import settings


class Database:
    """Supabase database client singleton."""
    
    _instance: Optional["Database"] = None
    _client: Optional[Client] = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    @property
    def client(self) -> Client:
        """Get Supabase client instance."""
        if self._client is None:
            if not settings.supabase_url or not settings.supabase_key:
                raise RuntimeError(
                    "Supabase credentials not configured. "
                    "Set SUPABASE_URL and SUPABASE_KEY environment variables."
                )
            self._client = create_client(
                settings.supabase_url,
                settings.supabase_key
            )
        return self._client
    
    @property
    def table(self):
        """Access database tables."""
        return self.client.table
    
    async def health_check(self) -> Dict[str, Any]:
        """Check database connection health."""
        try:
            # Try a simple query
            result = self.client.table('exercises').select('id').limit(1).execute()
            return {
                "status": "healthy",
                "connected": True,
                "error": None
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "connected": False,
                "error": str(e)
            }


# Global database instance
db = Database()


# ============== Repository Pattern ==============

class ExerciseRepository:
    """Repository for exercise CRUD operations."""
    
    TABLE_NAME = "exercises"
    
    @classmethod
    async def get_all(cls, limit: int = 1000) -> List[Dict[str, Any]]:
        """Get all exercises from database."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").limit(limit).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch exercises: {e}")
    
    @classmethod
    async def get_by_id(cls, exercise_id: str) -> Optional[Dict[str, Any]]:
        """Get exercise by ID."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").eq("id", exercise_id).single().execute()
            return result.data
        except APIError:
            return None
    
    @classmethod
    async def get_by_category(cls, category: str) -> List[Dict[str, Any]]:
        """Get exercises by category."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").eq("category", category).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch exercises by category: {e}")
    
    @classmethod
    async def search_by_name(cls, name: str) -> List[Dict[str, Any]]:
        """Search exercises by name (case-insensitive)."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").ilike("name", f"%{name}%").execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to search exercises: {e}")
    
    @classmethod
    async def create(cls, exercise_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new exercise."""
        try:
            result = db.table(cls.TABLE_NAME).insert(exercise_data).execute()
            if not result.data:
                raise DatabaseError("Failed to create exercise: no data returned")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to create exercise: {e}")
    
    @classmethod
    async def update(cls, exercise_id: str, exercise_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update an exercise."""
        try:
            result = db.table(cls.TABLE_NAME).update(exercise_data).eq("id", exercise_id).execute()
            if not result.data:
                raise DatabaseError("Failed to update exercise: no data returned")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to update exercise: {e}")
    
    @classmethod
    async def delete(cls, exercise_id: str) -> bool:
        """Delete an exercise."""
        try:
            db.table(cls.TABLE_NAME).delete().eq("id", exercise_id).execute()
            return True
        except APIError as e:
            raise DatabaseError(f"Failed to delete exercise: {e}")
    
    @classmethod
    async def get_for_user(cls, user_id: str) -> List[Dict[str, Any]]:
        """Get exercises visible to user (global + user's custom)."""
        try:
            # Global exercises (created_by_user_id IS NULL)
            global_result = db.table(cls.TABLE_NAME).select("*").is_("created_by_user_id", None).execute()
            global_exercises = global_result.data or []
            
            # User's custom exercises
            user_result = db.table(cls.TABLE_NAME).select("*").eq("created_by_user_id", user_id).execute()
            user_exercises = user_result.data or []
            
            return global_exercises + user_exercises
        except APIError as e:
            raise DatabaseError(f"Failed to fetch exercises for user: {e}")


class UserRepository:
    """Repository for user data operations."""
    
    TABLE_NAME = "user_profiles"
    
    @classmethod
    async def get_by_id(cls, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user profile by ID."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").eq("id", user_id).single().execute()
            return result.data
        except APIError:
            return None
    
    @classmethod
    async def create_or_update(cls, user_id: str, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create or update user profile."""
        try:
            # Try upsert
            result = db.table(cls.TABLE_NAME).upsert({
                "id": user_id,
                **profile_data,
            }).execute()
            if not result.data:
                raise DatabaseError("Failed to save user profile")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to save user profile: {e}")


class AIMemoryRepository:
    """Repository for AI memory storage."""
    
    TABLE_NAME = "ai_memories"
    
    @classmethod
    async def store(cls, user_id: str, memory_type: str, data: Dict[str, Any], 
                    priority: str = "medium", tags: List[str] = None) -> Dict[str, Any]:
        """Store an AI memory."""
        try:
            memory_data = {
                "user_id": user_id,
                "type": memory_type,
                "data": data,
                "priority": priority,
                "tags": tags or [],
            }
            result = db.table(cls.TABLE_NAME).insert(memory_data).execute()
            if not result.data:
                raise DatabaseError("Failed to store AI memory")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to store AI memory: {e}")
    
    @classmethod
    async def get_by_user(cls, user_id: str, memory_type: str = None, limit: int = 50) -> List[Dict[str, Any]]:
        """Get AI memories for a user."""
        try:
            query = db.table(cls.TABLE_NAME).select("*").eq("user_id", user_id)
            if memory_type:
                query = query.eq("type", memory_type)
            result = query.order("created_at", desc=True).limit(limit).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch AI memories: {e}")


class DatabaseError(Exception):
    """Custom exception for database operations."""
    pass


# ============== Connection Health ==============

async def check_database_health() -> Dict[str, Any]:
    """Check if database connection is healthy."""
    return await db.health_check()
