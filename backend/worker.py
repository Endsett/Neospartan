"""ARQ Background Worker for NeoSpartan Backend."""

import asyncio
from typing import Dict, Any
from datetime import datetime

from arq import create_pool
from arq.connections import RedisSettings

from config import settings
from database import AIMemoryRepository
from ai_engine import GeminiAIEngine, AIWorkoutRequest


# Redis connection settings
redis_settings = RedisSettings.from_dsn(settings.redis_url)


async def generate_workout_task(ctx: Dict, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Background task to generate AI workout."""
    engine = GeminiAIEngine()
    
    request = AIWorkoutRequest(
        user_id=request_data["user_id"],
        fitness_level=request_data["fitness_level"],
        training_goal=request_data["training_goal"],
        preferred_duration=request_data["preferred_duration"],
        available_equipment=request_data.get("available_equipment", []),
        injuries_or_limitations=request_data.get("injuries_or_limitations", []),
    )
    
    try:
        protocol = await engine.generate_workout(request)
        
        # Store in AI memory
        await AIMemoryRepository.store(
            user_id=request_data["user_id"],
            memory_type="background_workout_generation",
            data={
                "request": request_data,
                "result": {
                    "title": protocol.title,
                    "tier": protocol.tier,
                    "exercise_count": len(protocol.exercises),
                },
                "timestamp": datetime.utcnow().isoformat(),
            },
            priority="medium",
            tags=["background", "workout", "ai"],
        )
        
        return {
            "success": True,
            "workout": {
                "title": protocol.title,
                "subtitle": protocol.subtitle,
                "tier": protocol.tier,
                "exercises": [
                    {
                        "name": ex.name,
                        "category": ex.category,
                        "sets": ex.sets,
                        "reps": ex.reps,
                        "rpe": ex.rpe,
                    }
                    for ex in protocol.exercises
                ],
            },
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


async def process_analytics_task(ctx: Dict, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """Background task to process user analytics."""
    # Simulate analytics processing
    await asyncio.sleep(2)
    
    return {
        "user_id": user_id,
        "processed": True,
        "timestamp": datetime.utcnow().isoformat(),
    }


async def startup(ctx: Dict):
    """Worker startup handler."""
    print("🚀 ARQ Worker started")


async def shutdown(ctx: Dict):
    """Worker shutdown handler."""
    print("🛑 ARQ Worker shutting down")


class WorkerSettings:
    """ARQ Worker configuration."""
    
    redis_settings = redis_settings
    
    functions = [
        generate_workout_task,
        process_analytics_task,
    ]
    
    on_startup = startup
    on_shutdown = shutdown
    
    # Worker settings
    max_jobs = settings.arq_max_jobs
    job_timeout = settings.arq_job_timeout
    
    # Retry settings
    retry_jobs = True
    max_tries = 3


# For running worker locally
if __name__ == "__main__":
    import arq
    arq.run_worker(WorkerSettings)
