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


class WarriorProfileRepository:
    """Repository for warrior progression data."""
    
    TABLE_NAME = "warrior_profiles"
    
    @classmethod
    async def get_by_user_id(cls, user_id: str) -> Optional[Dict[str, Any]]:
        """Get warrior profile by user ID."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").eq("user_id", user_id).single().execute()
            return result.data
        except APIError:
            return None
    
    @classmethod
    async def create_or_update(cls, user_id: str, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create or update warrior profile."""
        try:
            result = db.table(cls.TABLE_NAME).upsert({
                "user_id": user_id,
                **profile_data,
                "updated_at": "now()",
            }).execute()
            if not result.data:
                raise DatabaseError("Failed to save warrior profile")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to save warrior profile: {e}")
    
    @classmethod
    async def add_xp(cls, user_id: str, xp_amount: int, activity: str) -> Dict[str, Any]:
        """Add XP to warrior profile and check for rank up."""
        try:
            # Get current profile
            profile = await cls.get_by_user_id(user_id)
            if not profile:
                raise DatabaseError("Warrior profile not found")
            
            new_xp = profile.get("total_xp", 0) + xp_amount
            current_rank = profile.get("rank_level", 1)
            
            # Check for rank up
            rank_up = False
            new_rank = current_rank
            # Rank thresholds
            rank_thresholds = [0, 500, 1500, 3000, 5000, 8000, 12000, 20000, 35000, 60000]
            for i, threshold in enumerate(rank_thresholds[1:], start=2):
                if new_xp >= threshold and current_rank < i:
                    new_rank = i
                    rank_up = True
                    break
            
            update_data = {
                "total_xp": new_xp,
                "rank_level": new_rank,
                "updated_at": "now()",
            }
            
            if rank_up:
                update_data["rank_achieved_date"] = "now()"
            
            result = db.table(cls.TABLE_NAME).update(update_data).eq("user_id", user_id).execute()
            if not result.data:
                raise DatabaseError("Failed to update warrior XP")
            
            return {
                "profile": result.data[0],
                "xp_added": xp_amount,
                "rank_up": rank_up,
                "new_rank": new_rank if rank_up else None,
            }
        except APIError as e:
            raise DatabaseError(f"Failed to add XP: {e}")


class AchievementRepository:
    """Repository for achievements."""
    
    TABLE_NAME = "achievements"
    USER_ACHIEVEMENTS_TABLE = "user_achievements"
    
    @classmethod
    async def get_all(cls) -> List[Dict[str, Any]]:
        """Get all available achievements."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch achievements: {e}")
    
    @classmethod
    async def get_by_user(cls, user_id: str) -> List[Dict[str, Any]]:
        """Get user's unlocked achievements."""
        try:
            result = db.table(cls.USER_ACHIEVEMENTS_TABLE).select("*").eq("user_id", user_id).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch user achievements: {e}")
    
    @classmethod
    async def unlock(cls, user_id: str, achievement_id: str) -> Dict[str, Any]:
        """Unlock an achievement for a user."""
        try:
            result = db.table(cls.USER_ACHIEVEMENTS_TABLE).upsert({
                "user_id": user_id,
                "achievement_id": achievement_id,
                "unlocked_at": "now()",
            }).execute()
            if not result.data:
                raise DatabaseError("Failed to unlock achievement")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to unlock achievement: {e}")


class BattleChronicleRepository:
    """Repository for workout battle chronicle."""
    
    TABLE_NAME = "battle_chronicle"
    
    @classmethod
    async def add_entry(cls, user_id: str, entry_data: Dict[str, Any]) -> Dict[str, Any]:
        """Add a battle chronicle entry."""
        try:
            result = db.table(cls.TABLE_NAME).insert({
                "user_id": user_id,
                **entry_data,
                "created_at": "now()",
            }).execute()
            if not result.data:
                raise DatabaseError("Failed to add chronicle entry")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to add chronicle entry: {e}")
    
    @classmethod
    async def get_by_user(cls, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get user's battle chronicle entries."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").eq("user_id", user_id).order("created_at", desc=True).limit(limit).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch chronicle: {e}")


class WorkoutSessionRepository:
    """Repository for workout session tracking."""

    TABLE_NAME = "workout_sessions"
    EXERCISE_ENTRIES_TABLE = "workout_exercise_entries"
    SETS_TABLE = "workout_sets"

    @classmethod
    async def create_session(cls, user_id: str, session_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new workout session."""
        try:
            data = {
                "user_id": user_id,
                "name": session_data.get("name", "Untitled Workout"),
                "status": session_data.get("status", "planned"),
                "scheduled_date": session_data.get("scheduled_date"),
                "started_at": session_data.get("started_at"),
                "completed_at": session_data.get("completed_at"),
                "duration_seconds": session_data.get("duration_seconds", 0),
                "total_volume": session_data.get("total_volume", 0.0),
                "notes": session_data.get("notes", ""),
                "created_at": "now()",
            }
            result = db.table(cls.TABLE_NAME).insert(data).execute()
            if not result.data:
                raise DatabaseError("Failed to create workout session")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to create workout session: {e}")

    @classmethod
    async def get_by_user(cls, user_id: str, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
        """Get workout sessions for a user."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").eq("user_id", user_id).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch workout sessions: {e}")

    @classmethod
    async def get_by_id(cls, session_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific workout session with all exercise entries."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").eq("id", session_id).eq("user_id", user_id).single().execute()
            if not result.data:
                return None

            session = result.data
            # Get exercise entries
            entries_result = db.table(cls.EXERCISE_ENTRIES_TABLE).select("*").eq("session_id", session_id).execute()
            session["exercises"] = entries_result.data or []

            # Get sets for each exercise
            for exercise in session["exercises"]:
                sets_result = db.table(cls.SETS_TABLE).select("*").eq("exercise_entry_id", exercise["id"]).execute()
                exercise["sets"] = sets_result.data or []

            return session
        except APIError:
            return None

    @classmethod
    async def update_session(cls, session_id: str, user_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update a workout session."""
        try:
            result = db.table(cls.TABLE_NAME).update(update_data).eq("id", session_id).eq("user_id", user_id).execute()
            if not result.data:
                raise DatabaseError("Failed to update workout session")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to update workout session: {e}")

    @classmethod
    async def delete_session(cls, session_id: str, user_id: str) -> bool:
        """Delete a workout session and all related data."""
        try:
            # Delete sets first (cascade)
            db.table(cls.SETS_TABLE).delete().eq("session_id", session_id).execute()
            # Delete exercise entries
            db.table(cls.EXERCISE_ENTRIES_TABLE).delete().eq("session_id", session_id).execute()
            # Delete session
            db.table(cls.TABLE_NAME).delete().eq("id", session_id).eq("user_id", user_id).execute()
            return True
        except APIError as e:
            raise DatabaseError(f"Failed to delete workout session: {e}")

    @classmethod
    async def add_exercise_entry(cls, session_id: str, exercise_data: Dict[str, Any]) -> Dict[str, Any]:
        """Add an exercise entry to a session."""
        try:
            data = {
                "session_id": session_id,
                "exercise_id": exercise_data["exercise_id"],
                "exercise_name": exercise_data.get("exercise_name", ""),
                "target_sets": exercise_data.get("target_sets", 3),
                "target_reps": exercise_data.get("target_reps", 10),
                "target_weight": exercise_data.get("target_weight", 0.0),
                "rest_seconds": exercise_data.get("rest_seconds", 60),
                "notes": exercise_data.get("notes", ""),
                "order_index": exercise_data.get("order_index", 0),
                "created_at": "now()",
            }
            result = db.table(cls.EXERCISE_ENTRIES_TABLE).insert(data).execute()
            if not result.data:
                raise DatabaseError("Failed to add exercise entry")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to add exercise entry: {e}")

    @classmethod
    async def add_set(cls, exercise_entry_id: str, session_id: str, set_data: Dict[str, Any]) -> Dict[str, Any]:
        """Add a set to an exercise entry."""
        try:
            data = {
                "exercise_entry_id": exercise_entry_id,
                "session_id": session_id,
                "set_number": set_data["set_number"],
                "reps": set_data.get("reps", 0),
                "weight": set_data.get("weight", 0.0),
                "rpe": set_data.get("rpe"),
                "is_completed": set_data.get("is_completed", False),
                "notes": set_data.get("notes", ""),
                "created_at": "now()",
            }
            result = db.table(cls.SETS_TABLE).insert(data).execute()
            if not result.data:
                raise DatabaseError("Failed to add set")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to add set: {e}")

    @classmethod
    async def complete_session(cls, session_id: str, user_id: str, completion_data: Dict[str, Any]) -> Dict[str, Any]:
        """Mark a workout session as completed with final stats."""
        try:
            update_data = {
                "status": "completed",
                "completed_at": "now()",
                "duration_seconds": completion_data.get("duration_seconds", 0),
                "total_volume": completion_data.get("total_volume", 0.0),
                "notes": completion_data.get("notes", ""),
            }
            result = db.table(cls.TABLE_NAME).update(update_data).eq("id", session_id).eq("user_id", user_id).execute()
            if not result.data:
                raise DatabaseError("Failed to complete workout session")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to complete workout session: {e}")


class NotificationRepository:
    """Repository for user notifications."""

    TABLE_NAME = "notifications"

    @classmethod
    async def create(cls, user_id: str, notification_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new notification."""
        try:
            data = {
                "user_id": user_id,
                "type": notification_data["type"],
                "title": notification_data["title"],
                "message": notification_data["message"],
                "data": notification_data.get("data", {}),
                "is_read": False,
                "action_url": notification_data.get("action_url"),
                "created_at": "now()",
            }
            result = db.table(cls.TABLE_NAME).insert(data).execute()
            if not result.data:
                raise DatabaseError("Failed to create notification")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to create notification: {e}")

    @classmethod
    async def get_by_user(cls, user_id: str, limit: int = 50, include_read: bool = False) -> List[Dict[str, Any]]:
        """Get notifications for a user."""
        try:
            query = db.table(cls.TABLE_NAME).select("*").eq("user_id", user_id)
            if not include_read:
                query = query.eq("is_read", False)
            result = query.order("created_at", desc=True).limit(limit).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch notifications: {e}")

    @classmethod
    async def mark_as_read(cls, notification_id: str, user_id: str) -> Dict[str, Any]:
        """Mark a notification as read."""
        try:
            result = db.table(cls.TABLE_NAME).update({"is_read": True, "read_at": "now()"}).eq("id", notification_id).eq("user_id", user_id).execute()
            if not result.data:
                raise DatabaseError("Failed to mark notification as read")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to mark notification as read: {e}")

    @classmethod
    async def mark_all_as_read(cls, user_id: str) -> bool:
        """Mark all notifications as read for a user."""
        try:
            db.table(cls.TABLE_NAME).update({"is_read": True, "read_at": "now()"}).eq("user_id", user_id).eq("is_read", False).execute()
            return True
        except APIError as e:
            raise DatabaseError(f"Failed to mark all notifications as read: {e}")

    @classmethod
    async def delete_old_notifications(cls, user_id: str, days: int = 30) -> bool:
        """Delete notifications older than specified days."""
        try:
            from datetime import datetime, timedelta
            cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
            db.table(cls.TABLE_NAME).delete().eq("user_id", user_id).lt("created_at", cutoff_date).execute()
            return True
        except APIError as e:
            raise DatabaseError(f"Failed to delete old notifications: {e}")

    @classmethod
    async def get_unread_count(cls, user_id: str) -> int:
        """Get count of unread notifications."""
        try:
            result = db.table(cls.TABLE_NAME).select("id", count="exact").eq("user_id", user_id).eq("is_read", False).execute()
            return result.count or 0
        except APIError:
            return 0


class ProgressRepository:
    """Repository for user progress tracking and analytics."""

    TABLE_NAME = "progress_metrics"
    PERSONAL_RECORDS_TABLE = "personal_records"

    @classmethod
    async def record_metric(cls, user_id: str, metric_data: Dict[str, Any]) -> Dict[str, Any]:
        """Record a progress metric (weight, body fat, measurements, etc.)."""
        try:
            data = {
                "user_id": user_id,
                "metric_type": metric_data["metric_type"],  # weight, body_fat, measurement, etc.
                "value": metric_data["value"],
                "unit": metric_data.get("unit", ""),
                "notes": metric_data.get("notes", ""),
                "measured_at": metric_data.get("measured_at", "now()"),
                "created_at": "now()",
            }
            result = db.table(cls.TABLE_NAME).insert(data).execute()
            if not result.data:
                raise DatabaseError("Failed to record progress metric")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to record progress metric: {e}")

    @classmethod
    async def get_metrics(cls, user_id: str, metric_type: str = None, limit: int = 100) -> List[Dict[str, Any]]:
        """Get progress metrics for a user."""
        try:
            query = db.table(cls.TABLE_NAME).select("*").eq("user_id", user_id)
            if metric_type:
                query = query.eq("metric_type", metric_type)
            result = query.order("measured_at", desc=True).limit(limit).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch progress metrics: {e}")

    @classmethod
    async def record_personal_record(cls, user_id: str, pr_data: Dict[str, Any]) -> Dict[str, Any]:
        """Record a personal record for an exercise."""
        try:
            data = {
                "user_id": user_id,
                "exercise_id": pr_data["exercise_id"],
                "exercise_name": pr_data.get("exercise_name", ""),
                "metric_type": pr_data["metric_type"],  # weight, reps, volume
                "value": pr_data["value"],
                "previous_value": pr_data.get("previous_value"),
                "improvement_percent": pr_data.get("improvement_percent", 0.0),
                "achieved_at": pr_data.get("achieved_at", "now()"),
                "created_at": "now()",
            }
            result = db.table(cls.PERSONAL_RECORDS_TABLE).insert(data).execute()
            if not result.data:
                raise DatabaseError("Failed to record personal record")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to record personal record: {e}")

    @classmethod
    async def get_personal_records(cls, user_id: str, exercise_id: str = None, limit: int = 50) -> List[Dict[str, Any]]:
        """Get personal records for a user."""
        try:
            query = db.table(cls.PERSONAL_RECORDS_TABLE).select("*").eq("user_id", user_id)
            if exercise_id:
                query = query.eq("exercise_id", exercise_id)
            result = query.order("achieved_at", desc=True).limit(limit).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch personal records: {e}")


class AnalyticsRepository:
    """Repository for analytics data."""

    TABLE_NAME = "analytics"

    @classmethod
    async def record_event(cls, event_data: Dict[str, Any]) -> Dict[str, Any]:
        """Record an analytics event."""
        try:
            data = {
                "event_type": event_data["event_type"],
                "event_data": event_data.get("event_data", {}),
                "created_at": "now()",
            }
            result = db.table(cls.TABLE_NAME).insert(data).execute()
            if not result.data:
                raise DatabaseError("Failed to record analytics event")
            return result.data[0]
        except APIError as e:
            raise DatabaseError(f"Failed to record analytics event: {e}")

    @classmethod
    async def get_events(cls, limit: int = 100) -> List[Dict[str, Any]]:
        """Get analytics events."""
        try:
            result = db.table(cls.TABLE_NAME).select("*").order("created_at", desc=True).limit(limit).execute()
            return result.data or []
        except APIError as e:
            raise DatabaseError(f"Failed to fetch analytics events: {e}")


class DatabaseError(Exception):
    """Custom exception for database operations."""
    pass


# ============== Connection Health ==============

async def check_database_health() -> Dict[str, Any]:
    """Check if database connection is healthy."""
    return await db.health_check()
