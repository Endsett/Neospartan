"""NeoSpartan AI Backend - Full Deployment Version.

Production-ready FastAPI server with:
- Supabase PostgreSQL integration
- Google Gemini AI for workout generation
- JWT authentication
- WebSocket real-time updates
- Background task processing
"""

import os
import json
import asyncio
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any, Tuple
from enum import Enum
from dataclasses import dataclass, field
from contextlib import asynccontextmanager

import numpy as np
from fastapi import FastAPI, HTTPException, Request, Depends, WebSocket, WebSocketDisconnect, status, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# Internal imports
from config import settings
from database import (
    db, 
    check_database_health,
    ExerciseRepository, 
    UserRepository, 
    AIMemoryRepository,
    WarriorProfileRepository,
    AchievementRepository,
    BattleChronicleRepository,
    WorkoutSessionRepository,
    NotificationRepository,
    ProgressRepository,
    DatabaseError
)
from ai_engine import (
    GeminiAIEngine, 
    DOMRLEngine, 
    AIWorkoutRequest,
    AIWorkoutProtocol,
    AIEngineError,
    gemini_engine,
    dom_rl_engine
)
from auth import (
    get_current_user,
    get_current_active_user,
    require_admin,
    create_access_token,
    verify_token,
    get_current_user_supabase
)
from websocket_manager import manager
from cache import cache, cached, invalidate_cache, CACHE_TTL
from rate_limiter import rate_limiter, RateLimitTier, rate_limit, auth_rate_limit, ai_rate_limit, public_rate_limit
from middleware import (
    RequestIDMiddleware,
    TimingMiddleware,
    ErrorHandlingMiddleware,
    SecurityHeadersMiddleware
)

# Initialize FastAPI with lifespan
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    print(f"🚀 Starting {settings.app_name} v{settings.app_version}")
    
    # Check database connection
    health = await check_database_health()
    if not health["connected"]:
        print(f"⚠️  Database connection warning: {health.get('error')}")
    else:
        print("✅ Database connected")
    
    # Connect to Redis for caching and rate limiting
    await cache.connect()
    await rate_limiter.connect()
    
    yield
    
    # Shutdown
    print("🛑 Shutting down...")
    await cache.disconnect()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Production NeoSpartan AI Backend with Supabase and Gemini",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Trusted host middleware
app.add_middleware(
    TrustedHostMiddleware, 
    allowed_hosts=settings.allowed_hosts_list
)

# Custom middleware for enhanced functionality
app.add_middleware(ErrorHandlingMiddleware)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RequestIDMiddleware)
app.add_middleware(TimingMiddleware, slow_threshold=2.0)

# Rate limiting (simple in-memory, use Redis in production)
request_counts: Dict[str, List[datetime]] = {}

async def check_rate_limit(client_ip: str) -> bool:
    """Check if request is within rate limit."""
    now = datetime.now()
    if client_ip not in request_counts:
        request_counts[client_ip] = []
    
    # Remove old requests
    request_counts[client_ip] = [
        t for t in request_counts[client_ip] 
        if now - t < timedelta(seconds=settings.rate_limit_window)
    ]
    
    if len(request_counts[client_ip]) >= settings.rate_limit:
        return False
    
    request_counts[client_ip].append(now)
    return True

# ============== NEW ENDPOINTS ==============

class GenerateWorkoutRequest(BaseModel):
    """Request model for AI workout generation."""
    fitness_level: str = "intermediate"
    training_goal: str = "general combat readiness"
    preferred_duration: int = 45
    available_equipment: List[str] = ["dumbbells", "kettlebells", "bodyweight"]
    injuries_or_limitations: List[str] = []
    preferred_categories: List[str] = None

class AIWorkoutResponse(BaseModel):
    """Response model for AI workout generation."""
    title: str
    subtitle: str
    tier: str
    mindset_prompt: str
    estimated_duration: int
    exercises: List[Dict[str, Any]]
    ai_generated: bool
    fallback_used: bool

@app.post("/ai/workout/generate", response_model=AIWorkoutResponse)
async def ai_generate_workout(
    request: GenerateWorkoutRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """
    Generate an AI-powered workout using Google Gemini.
    Falls back to DOM-RL engine if AI is unavailable.
    """
    user_id = current_user["id"]
    
    # Build AI request
    ai_request = AIWorkoutRequest(
        user_id=user_id,
        fitness_level=request.fitness_level,
        training_goal=request.training_goal,
        preferred_duration=request.preferred_duration,
        available_equipment=request.available_equipment,
        injuries_or_limitations=request.injuries_or_limitations,
        preferred_categories=request.preferred_categories,
    )
    
    try:
        # Try Gemini AI first
        protocol = await gemini_engine.generate_workout(ai_request)
        ai_generated = True
        fallback_used = False
    except AIEngineError as e:
        # Log error and fall back to DOM-RL
        print(f"⚠️  Gemini AI failed: {e}, using DOM-RL fallback")
        
        # Use DOM-RL as fallback
        readiness = 75  # Default to "ready" tier
        if request.fitness_level == "beginner":
            readiness = 60
        elif request.fitness_level == "advanced":
            readiness = 85
            
        action = dom_rl_engine.generate_action(readiness)
        
        # Create basic protocol from fallback
        protocol = AIWorkoutProtocol(
            title=f"DOM-RL: {request.training_goal.title()}",
            subtitle=f"Fallback protocol for {request.fitness_level} level",
            tier=action["focus_area"],
            mindset_prompt="Train with discipline and purpose.",
            estimated_duration=request.preferred_duration,
            exercises=[]
        )
        ai_generated = False
        fallback_used = True
    
    # Convert exercises to dict
    exercises_list = []
    for ex in protocol.exercises:
        exercises_list.append({
            "name": ex.name,
            "category": ex.category,
            "sets": ex.sets,
            "reps": ex.reps,
            "rpe": ex.rpe,
            "rest_seconds": ex.rest_seconds,
            "target_metaphor": ex.target_metaphor,
            "instructions": ex.instructions,
            "primary_muscles": ex.primary_muscles,
        })
    
    # Store in AI memory
    try:
        await AIMemoryRepository.store(
            user_id=user_id,
            memory_type="workout_generation",
            data={
                "request": request.dict(),
                "response": {
                    "title": protocol.title,
                    "tier": protocol.tier,
                    "exercise_count": len(protocol.exercises),
                },
                "ai_generated": ai_generated,
                "fallback_used": fallback_used,
            },
            priority="high",
            tags=["workout", "ai", protocol.tier],
        )
    except Exception as e:
        print(f"⚠️  Failed to store AI memory: {e}")
    
    return AIWorkoutResponse(
        title=protocol.title,
        subtitle=protocol.subtitle,
        tier=protocol.tier,
        mindset_prompt=protocol.mindset_prompt,
        estimated_duration=protocol.estimated_duration,
        exercises=exercises_list,
        ai_generated=ai_generated,
        fallback_used=fallback_used,
    )


@app.websocket("/ws/workout/{user_id}")
async def workout_websocket(websocket: WebSocket, user_id: str):
    """WebSocket endpoint for real-time workout updates."""
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            # Keep connection alive and handle client messages
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            if message.get("type") == "ping":
                await websocket.send_json({"type": "pong"})
            elif message.get("type") == "workout_started":
                await manager.send_to_user(user_id, {
                    "type": "acknowledged",
                    "message": "Workout session tracking started"
                })
            elif message.get("type") == "progress_update":
                # Broadcast progress to user's other connections
                await manager.send_to_user(user_id, {
                    "type": "progress_sync",
                    "data": message.get("data")
                })
                
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        print(f"WebSocket error for user {user_id}: {e}")
        manager.disconnect(websocket)


@app.get("/exercises/dynamic")
async def get_exercises_dynamic(
    category: Optional[str] = None,
    search: Optional[str] = None,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """
    Get exercises from Supabase database (dynamic library).
    Returns global exercises + user's custom exercises.
    """
    user_id = current_user["id"]
    
    try:
        if search:
            # Search by name
            exercises = await ExerciseRepository.search_by_name(search)
        elif category:
            # Filter by category
            exercises = await ExerciseRepository.get_by_category(category)
        else:
            # Get all exercises for user
            exercises = await ExerciseRepository.get_for_user(user_id)
        
        return {
            "exercises": exercises,
            "count": len(exercises),
            "source": "supabase",
            "user_id": user_id,
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {e}")


@app.post("/exercises/create")
async def create_exercise(
    exercise_data: Dict[str, Any],
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Create a new custom exercise for the user."""
    user_id = current_user["id"]
    
    # Add user ID to exercise
    exercise_data["created_by_user_id"] = user_id
    
    try:
        exercise = await ExerciseRepository.create(exercise_data)
        return {
            "exercise": exercise,
            "message": "Exercise created successfully",
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=f"Failed to create exercise: {e}")


@app.get("/health/detailed")
async def detailed_health_check():
    """Detailed health check including database status."""
    db_health = await check_database_health()
    
    return {
        "status": "healthy" if db_health["connected"] else "degraded",
        "version": settings.app_version,
        "environment": settings.environment,
        "timestamp": datetime.now().isoformat(),
        "services": {
            "database": db_health,
            "ai_engine": {
                "gemini_configured": bool(settings.gemini_api_key),
                "model": settings.gemini_model if settings.gemini_api_key else None,
            },
            "websockets": {
                "online_users": manager.get_online_users_count(),
                "total_connections": manager.get_total_connections(),
            },
        },
    }


# ============== EXISTING ENDPOINTS (Updated) ==============

# ============ DATA MODELS ============

class ExerciseCategory(str, Enum):
    plyometric = "plyometric"
    isometric = "isometric"
    combat = "combat"
    strength = "strength"
    mobility = "mobility"
    sprint = "sprint"

class ProtocolTier(str, Enum):
    elite = "elite"
    ready = "ready"
    fatigued = "fatigued"
    recovery = "recovery"

class Exercise(BaseModel):
    id: str
    name: str
    category: ExerciseCategory
    youtube_id: str
    target_metaphor: str
    instructions: str
    intensity_level: int = 5
    primary_muscles: List[str] = []
    joint_stress: Dict[str, int] = {}  # joint -> stress level 1-10

class WorkoutEntry(BaseModel):
    exercise: Exercise
    sets: int
    reps: int
    intensity_rpe: float
    rest_seconds: int
    completed: bool = False
    actual_rpe: Optional[float] = None

class WorkoutProtocol(BaseModel):
    title: str
    subtitle: str
    tier: ProtocolTier
    entries: List[WorkoutEntry]
    estimated_duration_minutes: int
    mindset_prompt: str
    date_created: datetime = Field(default_factory=datetime.now)

class Biometrics(BaseModel):
    hrv: float
    sleep_hours: float
    resting_hr: float
    timestamp: datetime

class DailyLog(BaseModel):
    date: datetime
    rpe_entries: List[float] = []  # RPE scores for each exercise
    sleep_quality: int = 5  # 1-10
    joint_fatigue: Dict[str, int] = {}  # joint -> fatigue 1-10
    flow_state: int = 5  # 1-10 mental engagement
    readiness_score: int = 0

class MicroCycle(BaseModel):
    days: List[DailyLog] = []
    start_date: datetime
    end_date: datetime

class DOMRLState(BaseModel):
    readiness_score: int
    weekly_volume: float
    fatigue_accumulation: Dict[str, float]
    power_output_trend: List[float] = []
    recovery_metrics: List[float] = []
    joint_load_history: Dict[str, List[float]] = {}

class DOMRLAction(BaseModel):
    volume_adjustment: float  # -1.0 to 1.0
    intensity_adjustment: float  # -1.0 to 1.0
    exercise_substitutions: List[Tuple[str, str]] = []  # (from_id, to_id)
    rest_adjustment: int  # seconds to add/subtract
    focus_area: Optional[str] = None  # "power", "endurance", "recovery"

# Re-import Field
from pydantic import Field

# ============ EXPANDED EXERCISE LIBRARY ============

EXERCISE_LIBRARY = [
    # PLYOMETRIC - Explosive Power
    Exercise(
        id="ex_001",
        name="PHALANX PUSH-UPS",
        category=ExerciseCategory.plyometric,
        youtube_id="IODxDxX7oi4",
        target_metaphor="Unbreakable Wall",
        instructions="Explosive push-ups with a narrow hand placement.",
        intensity_level=8,
        primary_muscles=["chest", "triceps", "shoulders"],
        joint_stress={"wrists": 6, "shoulders": 7, "elbows": 5}
    ),
    Exercise(
        id="ex_002",
        name="THERMOPYLAE THRUSTERS",
        category=ExerciseCategory.plyometric,
        youtube_id="rZ_9GzNUP_M",
        target_metaphor="Defy the Odds",
        instructions="Full squat into overhead press. Maximum explosive power.",
        intensity_level=9,
        primary_muscles=["quads", "glutes", "shoulders", "traps"],
        joint_stress={"knees": 8, "shoulders": 7, "hips": 6}
    ),
    Exercise(
        id="ex_003",
        name="PLIO SPARTAN BURPEE",
        category=ExerciseCategory.plyometric,
        youtube_id="L61p2B9M2wo",
        target_metaphor="Rise from the Ash",
        instructions="Explosive burpee with tuck jump. Triple extension focus.",
        intensity_level=10,
        primary_muscles=["full_body"],
        joint_stress={"knees": 9, "wrists": 6, "ankles": 7}
    ),
    Exercise(
        id="ex_004",
        name="BOX JUMP ASCENSION",
        category=ExerciseCategory.plyometric,
        youtube_id="xFfhlTjNJL8",
        target_metaphor="Mount Olympus",
        instructions="Explosive box jumps focusing on soft landings.",
        intensity_level=9,
        primary_muscles=["quads", "glutes", "calves"],
        joint_stress={"knees": 8, "ankles": 7}
    ),
    
    # ISOMETRIC - Endurance & Stability
    Exercise(
        id="ex_005",
        name="STOIC PLANK",
        category=ExerciseCategory.isometric,
        youtube_id="pSHjTRCQxIw",
        target_metaphor="The Pillars of Hercules",
        instructions="Low plank held with absolute stillness. Focus on the breath.",
        intensity_level=6,
        primary_muscles=["core", "shoulders"],
        joint_stress={"shoulders": 4, "lower_back": 5}
    ),
    Exercise(
        id="ex_006",
        name="IRON ISO SHADOWBOX",
        category=ExerciseCategory.isometric,
        youtube_id="WpYm78WJ2U0",
        target_metaphor="Unmoving Spear",
        instructions="Hold boxing guard position with light weights. Isometric shoulder endurance.",
        intensity_level=7,
        primary_muscles=["shoulders", "traps", "core"],
        joint_stress={"shoulders": 6, "wrists": 4}
    ),
    Exercise(
        id="ex_007",
        name="WALL SIT AEGIS",
        category=ExerciseCategory.isometric,
        youtube_id="y-wV4et0t0o",
        target_metaphor="The Shield Wall",
        instructions="Wall sit with weights held at shoulder height.",
        intensity_level=7,
        primary_muscles=["quads", "shoulders"],
        joint_stress={"knees": 6}
    ),
    Exercise(
        id="ex_008",
        name="L-SIT HANG",
        category=ExerciseCategory.isometric,
        youtube_id="IUZ25V9s6zw",
        target_metaphor="Suspend in Void",
        instructions="L-sit position on parallettes or floor. Core compression.",
        intensity_level=8,
        primary_muscles=["core", "hip_flexors", "triceps"],
        joint_stress={"wrists": 6, "shoulders": 5}
    ),
    
    # STRENGTH - Power Foundation
    Exercise(
        id="ex_009",
        name="LEONIDAS LUNGES",
        category=ExerciseCategory.strength,
        youtube_id="QOVaHwknd2w",
        target_metaphor="The Shield of Archidamus",
        instructions="Weighted lunges with a vertical posture. Keep your core tight like a phalanx.",
        intensity_level=7,
        primary_muscles=["quads", "glutes", "hamstrings"],
        joint_stress={"knees": 6, "hips": 5}
    ),
    Exercise(
        id="ex_010",
        name="HELLENIC DEADLIFTS",
        category=ExerciseCategory.strength,
        youtube_id="ytGaGIn6SjE",
        target_metaphor="The Weight of the World",
        instructions="Conventional deadlifts focusing on posterior chain engagement.",
        intensity_level=9,
        primary_muscles=["hamstrings", "glutes", "back", "traps"],
        joint_stress={"lower_back": 8, "knees": 5}
    ),
    Exercise(
        id="ex_011",
        name="KETTLEBELL SWING WARHAMMER",
        category=ExerciseCategory.strength,
        youtube_id="YSxHifyI6s8",
        target_metaphor="Crush the Enemy",
        instructions="Russian kettlebell swings with powerful hip extension.",
        intensity_level=8,
        primary_muscles=["posterior_chain", "core"],
        joint_stress={"lower_back": 6, "shoulders": 5}
    ),
    Exercise(
        id="ex_012",
        name="PULL-UP ASCENT",
        category=ExerciseCategory.strength,
        youtube_id="eGo4IYlbE5g",
        target_metaphor="Scale the Walls",
        instructions="Strict pull-ups, full range of motion, controlled tempo.",
        intensity_level=8,
        primary_muscles=["lats", "biceps", "core"],
        joint_stress={"shoulders": 6, "elbows": 5}
    ),
    
    # COMBAT - Fighting Specific
    Exercise(
        id="ex_013",
        name="STADION SPRINTS",
        category=ExerciseCategory.combat,
        youtube_id="m_Z9yKkU2N8",
        target_metaphor="Swift as Hermes",
        instructions="30-second max effort sprints followed by 60-second recovery.",
        intensity_level=10,
        primary_muscles=["legs", "core"],
        joint_stress={"knees": 7, "ankles": 6, "hips": 5}
    ),
    Exercise(
        id="ex_014",
        name="ROTATIONAL MED BALL SLAM",
        category=ExerciseCategory.combat,
        youtube_id="XJzBLNE_1Q0",
        target_metaphor="The Spear Throw",
        instructions="Explosive rotational med ball slams. Hip drive through core.",
        intensity_level=9,
        primary_muscles=["core", "obliques", "shoulders"],
        joint_stress={"spine": 6, "shoulders": 6}
    ),
    Exercise(
        id="ex_015",
        name="BATTLE ROPE TITAN",
        category=ExerciseCategory.combat,
        youtube_id="A5ZeaEElWjY",
        target_metaphor="Wrath of Poseidon",
        instructions="Alternating battle rope waves with squat stance.",
        intensity_level=8,
        primary_muscles=["shoulders", "core", "legs"],
        joint_stress={"shoulders": 7}
    ),
    Exercise(
        id="ex_016",
        name="SLED PUSH PHALANX",
        category=ExerciseCategory.combat,
        youtube_id="pASwB0fmoOM",
        target_metaphor="Drive the Line",
        instructions="Heavy sled push for distance. Low stance, driving legs.",
        intensity_level=9,
        primary_muscles=["legs", "core", "upper_back"],
        joint_stress={"knees": 7, "hips": 6}
    ),
    
    # SPRINT - Alactic Power
    Exercise(
        id="ex_017",
        name="HILL SPRINT CONQUEST",
        category=ExerciseCategory.sprint,
        youtube_id="wS4OsJ4ytP0",
        target_metaphor="Seize the High Ground",
        instructions="Max effort hill sprints. Walk down recovery.",
        intensity_level=10,
        primary_muscles=["legs", "glutes"],
        joint_stress={"knees": 8, "ankles": 6}
    ),
    Exercise(
        id="ex_018",
        name="PROWLER SPRINT",
        category=ExerciseCategory.sprint,
        youtube_id="qfQyB1JeJrI",
        target_metaphor="The Chariot Charge",
        instructions="Loaded prowler sprint for 20-40m.",
        intensity_level=9,
        primary_muscles=["legs", "core"],
        joint_stress={"knees": 7, "hips": 6}
    ),
    
    # MOBILITY - Recovery
    Exercise(
        id="ex_019",
        name="90/90 HIP SWITCH",
        category=ExerciseCategory.mobility,
        youtube_id="C9Jv7hD6kpw",
        target_metaphor="The Flexible Shield",
        instructions="Hip mobility drill for internal/external rotation.",
        intensity_level=3,
        primary_muscles=["hips"],
        joint_stress={"hips": 2}
    ),
    Exercise(
        id="ex_020",
        name="THORACIC BRIDGE FLOW",
        category=ExerciseCategory.mobility,
        youtube_id="CQNJvoCqzrs",
        target_metaphor="The Archer's Extension",
        instructions="Spine mobility flow through thoracic extension.",
        intensity_level=4,
        primary_muscles=["spine", "shoulders"],
        joint_stress={"spine": 3, "shoulders": 3}
    ),
]

# ============ STOIC PHILOSOPHY DATABASE ============

STOIC_QUOTES = [
    {"text": "We suffer more often in imagination than in reality.", "author": "Seneca the Younger"},
    {"text": "The obstacle is the way.", "author": "Marcus Aurelius"},
    {"text": "You have power over your mind - not outside events.", "author": "Marcus Aurelius"},
    {"text": "He who fears death will never do anything worthy of a man.", "author": "Seneca the Younger"},
    {"text": "Waste no more time arguing what a good man should be. Be one.", "author": "Marcus Aurelius"},
    {"text": "Difficulties strengthen the mind, as labor does the body.", "author": "Seneca the Younger"},
    {"text": "The best revenge is to be unlike him who performed the injury.", "author": "Marcus Aurelius"},
    {"text": "No man is free who is not master of himself.", "author": "Epictetus"},
    {"text": "First say to yourself what you would be; then do what you have to do.", "author": "Epictetus"},
    {"text": "It is not death that a man should fear, but he should fear never beginning to live.", "author": "Marcus Aurelius"},
    {"text": "Only the educated are free.", "author": "Epictetus"},
    {"text": "He who has a why to live can bear almost any how.", "author": "Nietzsche (Stoic-adjacent)"},
]

SPARTAN_METAPHORS = [
    "Today you forge your shield. Tomorrow you stand the line.",
    "The phalanx is only as strong as its weakest warrior.",
    "Come back with your shield - or on it.",
    "Fear is the enemy. Discipline is your spear.",
    "The Agoge tests not your strength, but your will.",
    "A Spartan never retreats from discomfort.",
    "Your body is bronze. Your mind is iron.",
]

# ============ DOM-RL ENGINE ============

class DOMRLEngine:
    """Dynamic Multi-Objective Deep Reinforcement Learning Engine"""
    
    def __init__(self):
        self.power_weight = 0.4
        self.endurance_weight = 0.3
        self.recovery_weight = 0.3
        self.exploration_rate = 0.1
        
    def calculate_state(self, micro_cycle: MicroCycle) -> DOMRLState:
        """Convert micro-cycle data to RL state representation"""
        if not micro_cycle.days:
            return DOMRLState(
                readiness_score=75,
                weekly_volume=0.0,
                fatigue_accumulation={},
                power_output_trend=[],
                recovery_metrics=[]
            )
        
        # Calculate weekly volume
        weekly_volume = sum(len(day.rpe_entries) * sum(day.rpe_entries) / max(len(day.rpe_entries), 1) 
                          for day in micro_cycle.days)
        
        # Calculate fatigue accumulation per joint
        joint_fatigue = {}
        for day in micro_cycle.days:
            for joint, fatigue in day.joint_fatigue.items():
                if joint not in joint_fatigue:
                    joint_fatigue[joint] = []
                joint_fatigue[joint].append(fatigue)
        
        fatigue_accumulation = {
            joint: np.mean(values) * (1 + len(values) * 0.1)  # Accumulation factor
            for joint, values in joint_fatigue.items()
        }
        
        # Latest readiness
        latest_readiness = micro_cycle.days[-1].readiness_score if micro_cycle.days else 75
        
        return DOMRLState(
            readiness_score=latest_readiness,
            weekly_volume=weekly_volume,
            fatigue_accumulation=fatigue_accumulation,
            power_output_trend=[day.readiness_score for day in micro_cycle.days],
            recovery_metrics=[10 - day.joint_fatigue.get("knees", 0) for day in micro_cycle.days]
        )
    
    def generate_action(self, state: DOMRLState) -> DOMRLAction:
        """Generate optimal action based on current state"""
        action = DOMRLAction(
            volume_adjustment=0.0,
            intensity_adjustment=0.0,
            exercise_substitutions=[],
            rest_adjustment=0
        )
        
        readiness = state.readiness_score
        
        # Power vs Recovery balance
        if readiness >= 85:
            # Elite readiness - push power
            action.volume_adjustment = 0.2
            action.intensity_adjustment = 0.15
            action.rest_adjustment = -10
            action.focus_area = "power"
        elif readiness >= 65:
            # Good readiness - maintain with slight power focus
            action.volume_adjustment = 0.0
            action.intensity_adjustment = 0.05
            action.rest_adjustment = 0
            action.focus_area = "balanced"
        elif readiness >= 45:
            # Moderate fatigue - reduce volume, maintain intensity
            action.volume_adjustment = -0.2
            action.intensity_adjustment = -0.1
            action.rest_adjustment = 15
            action.focus_area = "endurance"
        else:
            # High fatigue - recovery focus
            action.volume_adjustment = -0.5
            action.intensity_adjustment = -0.4
            action.rest_adjustment = 30
            action.focus_area = "recovery"
        
        # Check for joint stress and substitute exercises
        for joint, fatigue in state.fatigue_accumulation.items():
            if fatigue > 7:  # High joint stress
                # Find substitutions that reduce stress on this joint
                if joint == "knees":
                    action.exercise_substitutions.append(("ex_002", "ex_005"))  # Thrusters -> Plank
                elif joint == "lower_back":
                    action.exercise_substitutions.append(("ex_010", "ex_006"))  # Deadlifts -> Shadowbox
                elif joint == "shoulders":
                    action.exercise_substitutions.append(("ex_002", "ex_009"))  # Thrusters -> Lunges
        
        return action
    
    def optimize_protocol(self, base_protocol: WorkoutProtocol, 
                         action: DOMRLAction) -> WorkoutProtocol:
        """Apply action to modify protocol"""
        optimized_entries = []
        
        for entry in base_protocol.entries:
            # Check for substitutions
            new_exercise = entry.exercise
            for from_id, to_id in action.exercise_substitutions:
                if entry.exercise.id == from_id:
                    new_exercise = next((e for e in EXERCISE_LIBRARY if e.id == to_id), entry.exercise)
                    break
            
            # Adjust volume
            new_sets = max(1, int(entry.sets * (1 + action.volume_adjustment)))
            
            # Adjust intensity (RPE)
            new_rpe = max(3.0, min(10.0, entry.intensity_rpe + action.intensity_adjustment * 3))
            
            # Adjust rest
            new_rest = max(15, entry.rest_seconds + action.rest_adjustment)
            
            optimized_entries.append(WorkoutEntry(
                exercise=new_exercise,
                sets=new_sets,
                reps=entry.reps,
                intensity_rpe=round(new_rpe, 1),
                rest_seconds=new_rest
            ))
        
        # Update title based on focus
        focus_prefix = {
            "power": "CHARGE: ",
            "endurance": "HOLD: ",
            "recovery": "RESTORE: ",
            "balanced": ""
        }.get(action.focus_area, "")
        
        return WorkoutProtocol(
            title=focus_prefix + base_protocol.title,
            subtitle=f"AI-Optimized ({action.focus_area.upper()}) | {base_protocol.subtitle}",
            tier=base_protocol.tier,
            entries=optimized_entries,
            estimated_duration_minutes=int(base_protocol.estimated_duration_minutes * (1 + action.volume_adjustment * 0.5)),
            mindset_prompt=base_protocol.mindset_prompt
        )

# Initialize DOM-RL engine
rl_engine = DOMRLEngine()

# ============ API ENDPOINTS ============

def check_rate_limit(client_ip: str) -> bool:
    """Check if request is within rate limit"""
    now = datetime.now()
    if client_ip not in request_counts:
        request_counts[client_ip] = []
    
    # Remove old requests (> 1 minute)
    request_counts[client_ip] = [
        t for t in request_counts[client_ip] 
        if now - t < timedelta(minutes=1)
    ]
    
    # Check limit
    if len(request_counts[client_ip]) >= RATE_LIMIT:
        return False
    
    request_counts[client_ip].append(now)
    return True

@app.get("/")
def root():
    return {"message": "NeoSpartan AI Engine - DOM-RL Active", "version": "2.0.0"}

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "version": "2.0.0",
        "timestamp": datetime.now().isoformat(),
    }

@app.get("/exercises", response_model=List[Exercise])
def get_exercises(category: Optional[ExerciseCategory] = None):
    """Get exercise library, optionally filtered by category"""
    if category:
        return [e for e in EXERCISE_LIBRARY if e.category == category]
    return EXERCISE_LIBRARY

@app.get("/exercises/{exercise_id}", response_model=Exercise)
def get_exercise(exercise_id: str):
    """Get specific exercise by ID"""
    exercise = next((e for e in EXERCISE_LIBRARY if e.id == exercise_id), None)
    if not exercise:
        raise HTTPException(status_code=404, detail="Exercise not found")
    return exercise

@app.post("/dom-rl/optimize")
def optimize_with_domrl(micro_cycle: MicroCycle, base_protocol: WorkoutProtocol):
    """
    Run DOM-RL optimization on a base protocol given micro-cycle data.
    This is the core AI recommendation engine.
    """
    state = rl_engine.calculate_state(micro_cycle)
    action = rl_engine.generate_action(state)
    optimized = rl_engine.optimize_protocol(base_protocol, action)
    
    return {
        "optimized_protocol": optimized,
        "dom_rl_state": state,
        "dom_rl_action": action,
        "optimization_timestamp": datetime.now()
    }

@app.post("/ephor-scrutiny/analyze")
def ephor_scrutiny(micro_cycle: MicroCycle):
    """
    Weekly review analysis (Ephor Scrutiny).
    Analyzes past 7 days of data to generate next week's protocol.
    """
    if not micro_cycle.days or len(micro_cycle.days) < 3:
        return {
            "recommendation": "INSUFFICIENT_DATA",
            "message": "At least 3 days of data required for analysis",
            "next_week_protocol": None
        }
    
    # Calculate trends
    rpe_trend = [day.readiness_score for day in micro_cycle.days]
    avg_rpe = np.mean(rpe_trend)
    rpe_volatility = np.std(rpe_trend)
    
    sleep_trend = [day.sleep_quality for day in micro_cycle.days]
    avg_sleep = np.mean(sleep_trend)
    
    # Joint stress analysis
    all_joints = set()
    for day in micro_cycle.days:
        all_joints.update(day.joint_fatigue.keys())
    
    joint_stress_report = {}
    for joint in all_joints:
        values = [day.joint_fatigue.get(joint, 0) for day in micro_cycle.days]
        joint_stress_report[joint] = {
            "average": np.mean(values),
            "max": max(values),
            "trend": "increasing" if values[-1] > values[0] else "decreasing"
        }
    
    # Generate recommendation
    if avg_rpe < 50 and avg_sleep < 5:
        recommendation = "DELoad_RECOVERY"
        protocol_tier = ProtocolTier.recovery
        message = "Central nervous system shows signs of overreaching. Mandatory deload."
    elif avg_rpe < 65:
        recommendation = "MAINTENANCE"
        protocol_tier = ProtocolTier.fatigued
        message = "Fatigue accumulation detected. Reduce volume 30%, maintain intensity."
    elif avg_rpe > 85 and avg_sleep > 7:
        recommendation = "PROGRESSIVE_OVERLOAD"
        protocol_tier = ProtocolTier.elite
        message = "Excellent recovery metrics. Increase volume 10% and test new RPE thresholds."
    else:
        recommendation = "STEADY_STATE"
        protocol_tier = ProtocolTier.ready
        message = "Stable metrics. Continue current progression."
    
    return {
        "recommendation": recommendation,
        "protocol_tier": protocol_tier,
        "message": message,
        "metrics": {
            "avg_readiness": avg_rpe,
            "readiness_volatility": rpe_volatility,
            "avg_sleep_quality": avg_sleep,
            "joint_stress_report": joint_stress_report
        },
        "training_principles": [
            "Prioritize movements with lowest joint stress scores" if any(j["average"] > 6 for j in joint_stress_report.values()) else "Full movement library available",
            f"Target weekly volume: {len(micro_cycle.days) * 50 * (1.1 if protocol_tier == ProtocolTier.elite else 0.7 if protocol_tier == ProtocolTier.fatigued else 1.0):.0f} RPE-minutes"
        ]
    }

@app.post("/realtime-adaptation")
def realtime_adaptation(current_state: DOMRLState, performed_protocol: WorkoutProtocol):
    """
    Real-time protocol adjustment based on immediate performance feedback.
    If sprint times degrade but recovery is stable, recalibrate for power.
    """
    action = rl_engine.generate_action(current_state)
    
    # Check for specific conditions
    adjustments = []
    
    # Power degradation but good recovery = increase power stimulus
    if len(current_state.power_output_trend) >= 2:
        power_declining = current_state.power_output_trend[-1] < current_state.power_output_trend[0] * 0.95
        if power_declining and current_state.readiness_score > 70:
            adjustments.append("Power output declining but recovery stable. Adding plyometric activation work.")
            action.focus_area = "power"
            action.volume_adjustment = min(action.volume_adjustment + 0.1, 0.3)
    
    # High HRV but poor performance = CNS fatigue, not muscular
    if current_state.readiness_score > 80:
        if any(f > 6 for f in current_state.fatigue_accumulation.values()):
            adjustments.append("Mismatch: High HRV but joint stress elevated. Switching to non-impact movements.")
            action.focus_area = "endurance"
    
    adapted = rl_engine.optimize_protocol(performed_protocol, action)
    
    return {
        "adapted_protocol": adapted,
        "adjustments_made": adjustments,
        "adaptation_reason": action.focus_area,
        "next_session_recommendations": [
            f"Volume adjustment: {action.volume_adjustment:+.0%}",
            f"Intensity adjustment: {action.intensity_adjustment:+.0%}",
            f"Rest adjustment: {action.rest_adjustment:+d}s"
        ]
    }

@app.get("/stoic/primer")
def get_stoic_primer():
    """Get pre-battle primer (quote + metaphor)"""
    import random
    quote = random.choice(STOIC_QUOTES)
    metaphor = random.choice(SPARTAN_METAPHORS)
    
    return {
        "quote": quote,
        "metaphor": metaphor,
        "acknowledgment_required": True,
        "focus_prompt": "Acknowledge to proceed: I am master of my mind. External events do not control me."
    }

@app.get("/stoic/flow-prompts")
def get_flow_tracking_prompts():
    """Post-workout flow state assessment prompts"""
    return {
        "mental_engagement_questions": [
            "How present were you during the session? (1-10)",
            "Did external thoughts intrude? (1-10, higher = fewer intrusions)",
            "Rate your discipline in maintaining form. (1-10)"
        ],
        "correlation_factors": [
            "sleep_quality_correlation",
            "readiness_correlation",
            "time_of_day_correlation"
        ]
    }

@app.post("/armor-analytics/analyze")
def armor_analytics(micro_cycle: MicroCycle):
    """
    Joint and muscle group load analysis.
    Flags overuse risks before they become injuries.
    """
    joint_load_history = {}
    muscle_group_volume = {}
    
    for day in micro_cycle.days:
        # Accumulate joint stress
        for joint, fatigue in day.joint_fatigue.items():
            if joint not in joint_load_history:
                joint_load_history[joint] = []
            joint_load_history[joint].append(fatigue)
    
    # Calculate risk scores
    risk_flags = []
    for joint, loads in joint_load_history.items():
        avg_load = np.mean(loads)
        max_load = max(loads)
        trend = loads[-1] - loads[0]
        
        if avg_load > 6.5:
            risk_flags.append({
                "joint": joint,
                "risk_level": "HIGH",
                "message": f"{joint.upper()} averaging {avg_load:.1f}/10 stress. Mandatory 48hr rest from loading.",
                "recommendation": "SUBSTITUTE_LOW_IMPACT"
            })
        elif max_load > 8:
            risk_flags.append({
                "joint": joint,
                "risk_level": "CRITICAL",
                "message": f"{joint.upper()} peaked at {max_load}/10. Skip all {joint}-loading movements for 72hrs.",
                "recommendation": "FULL_REST"
            })
        elif trend > 2:
            risk_flags.append({
                "joint": joint,
                "risk_level": "ELEVATED",
                "message": f"{joint.upper()} stress trending upward. Reduce volume 20%.",
                "recommendation": "VOLUME_REDUCE"
            })
    
    return {
        "joint_load_history": joint_load_history,
        "risk_flags": risk_flags,
        "safe_movements": [
            e.id for e in EXERCISE_LIBRARY 
            if not any(r["joint"] in e.joint_stress and e.joint_stress[r["joint"]] > 3 
                      for r in risk_flags if r["risk_level"] in ["HIGH", "CRITICAL"])
        ],
        "summary": f"{len(risk_flags)} risk flags detected" if risk_flags else "All systems nominal"
    }

@app.post("/tactical-retreat/check")
def tactical_retreat_check(current_readiness: int, joint_stress: Dict[str, int]):
    """
    Check if user should be forced into recovery mode.
    Overrides heavy lifting when readiness drops below critical.
    """
    CRITICAL_READINESS = 35
    CRITICAL_JOINT_STRESS = 8
    
    should_retreat = False
    reasons = []
    enforced_protocol = None
    
    if current_readiness < CRITICAL_READINESS:
        should_retreat = True
        reasons.append(f"Readiness {current_readiness} below critical threshold {CRITICAL_READINESS}")
    
    critical_joints = [j for j, s in joint_stress.items() if s >= CRITICAL_JOINT_STRESS]
    if critical_joints:
        should_retreat = True
        reasons.append(f"Critical joint stress detected: {', '.join(critical_joints)}")
    
    if should_retreat:
        # Build recovery protocol
        recovery_entries = [
            WorkoutEntry(
                exercise=next(e for e in EXERCISE_LIBRARY if e.id == "ex_019"),  # Hip mobility
                sets=3,
                reps=0,
                intensity_rpe=3,
                rest_seconds=60
            ),
            WorkoutEntry(
                exercise=next(e for e in EXERCISE_LIBRARY if e.id == "ex_020"),  # Thoracic bridge
                sets=3,
                reps=0,
                intensity_rpe=3,
                rest_seconds=60
            ),
            WorkoutEntry(
                exercise=next(e for e in EXERCISE_LIBRARY if e.id == "ex_005"),  # Plank
                sets=2,
                reps=0,
                intensity_rpe=4,
                rest_seconds=90
            ),
        ]
        
        enforced_protocol = WorkoutProtocol(
            title="TACTICAL RETREAT: MANDATORY RECOVERY",
            subtitle="Your body demands restoration. Honor it.",
            tier=ProtocolTier.recovery,
            entries=recovery_entries,
            estimated_duration_minutes=25,
            mindset_prompt="The wise warrior knows when to rest. This is not weakness. This is strategy."
        )
    
    return {
        "should_retreat": should_retreat,
        "reasons": reasons,
        "enforced_protocol": enforced_protocol,
        "retreat_duration": "24-48 hours" if should_retreat else None,
        "recommendations": [
            "Prioritize sleep above 8 hours",
            "Hydration: 3L minimum",
            "Light movement only - walking, stretching",
            "No loading until readiness > 50"
        ] if should_retreat else []
    }

# ============ BASE PROTOCOLS ============

BASE_PROTOCOLS = {
    ProtocolTier.elite: WorkoutProtocol(
        title="THE SPARTAN CHARGE",
        subtitle="Maximum intensity for elite readiness",
        tier=ProtocolTier.elite,
        entries=[
            WorkoutEntry(exercise=EXERCISE_LIBRARY[2], sets=5, reps=0, intensity_rpe=10, rest_seconds=90),  # Burpee
            WorkoutEntry(exercise=EXERCISE_LIBRARY[1], sets=4, reps=12, intensity_rpe=9, rest_seconds=60),   # Thrusters
            WorkoutEntry(exercise=EXERCISE_LIBRARY[9], sets=5, reps=5, intensity_rpe=9, rest_seconds=120),    # Deadlifts
            WorkoutEntry(exercise=EXERCISE_LIBRARY[12], sets=5, reps=0, intensity_rpe=10, rest_seconds=90),   # Sprints
        ],
        estimated_duration_minutes=60,
        mindset_prompt="Leonidas would not hesitate. Push the limits of your endurance."
    ),
    ProtocolTier.ready: WorkoutProtocol(
        title="THE PHALANX",
        subtitle="Structured strength for combat readiness",
        tier=ProtocolTier.ready,
        entries=[
            WorkoutEntry(exercise=EXERCISE_LIBRARY[8], sets=4, reps=12, intensity_rpe=8, rest_seconds=60),  # Lunges
            WorkoutEntry(exercise=EXERCISE_LIBRARY[0], sets=4, reps=20, intensity_rpe=7, rest_seconds=45),     # Push-ups
            WorkoutEntry(exercise=EXERCISE_LIBRARY[4], sets=3, reps=0, intensity_rpe=6, rest_seconds=30),     # Plank
            WorkoutEntry(exercise=EXERCISE_LIBRARY[11], sets=4, reps=8, intensity_rpe=8, rest_seconds=90),     # Pull-ups
        ],
        estimated_duration_minutes=50,
        mindset_prompt="Consistency is the foundation of the phalanx. Maintain form."
    ),
    ProtocolTier.fatigued: WorkoutProtocol(
        title="THE GARRISON",
        subtitle="Maintenance and readiness preservation",
        tier=ProtocolTier.fatigued,
        entries=[
            WorkoutEntry(exercise=EXERCISE_LIBRARY[4], sets=3, reps=0, intensity_rpe=5, rest_seconds=60),  # Plank
            WorkoutEntry(exercise=EXERCISE_LIBRARY[8], sets=3, reps=10, intensity_rpe=6, rest_seconds=90),      # Lunges
            WorkoutEntry(exercise=EXERCISE_LIBRARY[5], sets=3, reps=0, intensity_rpe=5, rest_seconds=60),      # Shadowbox
        ],
        estimated_duration_minutes=35,
        mindset_prompt="A warrior knows when to hold the line and conserve strength."
    ),
    ProtocolTier.recovery: WorkoutProtocol(
        title="STOIC RESTORATION",
        subtitle="Mind over muscle - active recovery",
        tier=ProtocolTier.recovery,
        entries=[
            WorkoutEntry(exercise=EXERCISE_LIBRARY[18], sets=3, reps=0, intensity_rpe=3, rest_seconds=60), # Hip mobility
            WorkoutEntry(exercise=EXERCISE_LIBRARY[19], sets=3, reps=0, intensity_rpe=3, rest_seconds=60),     # Thoracic bridge
            WorkoutEntry(exercise=EXERCISE_LIBRARY[4], sets=2, reps=0, intensity_rpe=4, rest_seconds=90),      # Plank
        ],
        estimated_duration_minutes=25,
        mindset_prompt="Victory is won in recovery. Master the stillness."
    ),
}

@app.get("/protocols/base/{tier}")
def get_base_protocol(tier: ProtocolTier):
    """Get base protocol for a tier (before DOM-RL optimization)"""
    return BASE_PROTOCOLS.get(tier)

@app.get("/protocols/generate/{readiness_score}")
def generate_protocol(readiness_score: int, use_dom_rl: bool = False, micro_cycle: Optional[MicroCycle] = None):
    """
    Generate protocol based on readiness score.
    If use_dom_rl=True, will optimize using provided micro-cycle data.
    """
    # Determine base tier
    if readiness_score >= 85:
        tier = ProtocolTier.elite
    elif readiness_score >= 60:
        tier = ProtocolTier.ready
    elif readiness_score >= 40:
        tier = ProtocolTier.fatigued
    else:
        tier = ProtocolTier.recovery
    
    base_protocol = BASE_PROTOCOLS[tier]
    
    # Apply DOM-RL optimization if requested
    if use_dom_rl and micro_cycle:
        state = rl_engine.calculate_state(micro_cycle)
        action = rl_engine.generate_action(state)
        optimized = rl_engine.optimize_protocol(base_protocol, action)
        return {
            "protocol": optimized,
            "optimization_applied": True,
            "dom_rl_state": state,
            "dom_rl_action": action
        }
    
    return {
        "protocol": base_protocol,
        "optimization_applied": False
    }


# ============== Warrior Progression API ==============

class AddXPRequest(BaseModel):
    xp_amount: int = Field(..., gt=0, description="Amount of XP to add")
    activity: str = Field(..., description="Activity that earned the XP")

class ChronicleEntryRequest(BaseModel):
    trial_name: str = Field(..., description="Name of the trial/workout")
    difficulty: str = Field(..., description="Difficulty level")
    completion_rate: float = Field(..., ge=0.0, le=1.0, description="Completion percentage")
    casualties: int = Field(..., description="Calories burned")
    spoils: Dict[str, Any] = Field(default_factory=dict, description="Additional rewards/XP")
    wounds: List[str] = Field(default_factory=list, description="Muscle groups worked")

@app.get("/warrior/profile")
async def get_warrior_profile(current_user: Dict = Depends(get_current_user_supabase)):
    """Get the current user's warrior profile."""
    try:
        profile = await WarriorProfileRepository.get_by_user_id(current_user["id"])
        if not profile:
            # Create default profile
            profile = await WarriorProfileRepository.create_or_update(
                current_user["id"],
                {
                    "rank_level": 1,
                    "total_xp": 0,
                    "current_streak": 0,
                    "longest_streak": 0,
                    "total_workouts": 0,
                }
            )
        return {"profile": profile}
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/warrior/xp")
async def add_warrior_xp(
    request: AddXPRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Add XP to warrior profile and check for rank up."""
    try:
        result = await WarriorProfileRepository.add_xp(
            current_user["id"],
            request.xp_amount,
            request.activity
        )
        return result
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/warrior/achievements")
async def get_warrior_achievements(current_user: Dict = Depends(get_current_user_supabase)):
    """Get all available achievements and user's unlocked achievements."""
    try:
        all_achievements = await AchievementRepository.get_all()
        user_achievements = await AchievementRepository.get_by_user(current_user["id"])
        unlocked_ids = {a["achievement_id"] for a in user_achievements}
        
        return {
            "all_achievements": all_achievements,
            "unlocked_achievements": user_achievements,
            "unlocked_ids": list(unlocked_ids),
            "total_unlocked": len(user_achievements),
            "total_available": len(all_achievements),
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/warrior/achievements/{achievement_id}/unlock")
async def unlock_achievement(
    achievement_id: str,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Unlock an achievement for the current user."""
    try:
        result = await AchievementRepository.unlock(current_user["id"], achievement_id)
        return {"unlocked": result}
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/warrior/chronicle")
async def add_chronicle_entry(
    request: ChronicleEntryRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Add a battle chronicle entry for a completed workout."""
    try:
        entry = await BattleChronicleRepository.add_entry(
            current_user["id"],
            request.dict()
        )
        
        # Also increment total workouts
        profile = await WarriorProfileRepository.get_by_user_id(current_user["id"])
        if profile:
            await WarriorProfileRepository.create_or_update(
                current_user["id"],
                {
                    "total_workouts": profile.get("total_workouts", 0) + 1,
                }
            )
        
        return {"entry": entry}
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/warrior/chronicle")
async def get_chronicle(
    limit: int = 50,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get the user's battle chronicle entries."""
    try:
        entries = await BattleChronicleRepository.get_by_user(current_user["id"], limit)
        return {"entries": entries, "count": len(entries)}
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/warrior/ranks")
def get_warrior_ranks():
    """Get all warrior ranks and their requirements."""
    ranks = [
        {"level": 1, "name": "Helot", "subtitle": "Raw Recruit", "required_xp": 0, "icon": "shield"},
        {"level": 2, "name": "Perioikoi", "subtitle": "Trainee", "required_xp": 500, "icon": "fitness_center"},
        {"level": 3, "name": "Hypomeion", "subtitle": "Aspirant", "required_xp": 1500, "icon": "sports_martial_arts"},
        {"level": 4, "name": "Trophimoi", "subtitle": "Cadet", "required_xp": 3000, "icon": "local_fire_department"},
        {"level": 5, "name": "Spartiate", "subtitle": "Warrior", "required_xp": 5000, "icon": "military_tech"},
        {"level": 6, "name": "Harmost", "subtitle": "Squad Leader", "required_xp": 8000, "icon": "emoji_events"},
        {"level": 7, "name": "Lochagos", "subtitle": "Captain", "required_xp": 12000, "icon": "workspace_premium"},
        {"level": 8, "name": "Polemarch", "subtitle": "War Leader", "required_xp": 20000, "icon": "star"},
        {"level": 9, "name": "Strategos", "subtitle": "General", "required_xp": 35000, "icon": "workspace_premium"},
        {"level": 10, "name": "Archon", "subtitle": "Master", "required_xp": 60000, "icon": "military_tech"},
    ]
    return {"ranks": ranks}


# ============== Workout Session Management API ==============

class CreateWorkoutSessionRequest(BaseModel):
    name: str = Field(default="Workout Session", description="Name of the workout session")
    scheduled_date: Optional[str] = Field(None, description="Scheduled date for the workout")
    notes: Optional[str] = Field(None, description="Optional notes")

class AddExerciseEntryRequest(BaseModel):
    exercise_id: str = Field(..., description="ID of the exercise")
    exercise_name: str = Field(..., description="Name of the exercise")
    target_sets: int = Field(default=3, ge=1, description="Target number of sets")
    target_reps: int = Field(default=10, ge=1, description="Target number of reps")
    target_weight: float = Field(default=0.0, ge=0, description="Target weight")
    rest_seconds: int = Field(default=60, ge=0, description="Rest time in seconds")
    notes: Optional[str] = Field(None, description="Optional notes")
    order_index: int = Field(default=0, ge=0, description="Order in the workout")

class AddSetRequest(BaseModel):
    set_number: int = Field(..., ge=1, description="Set number")
    reps: int = Field(default=0, ge=0, description="Number of reps completed")
    weight: float = Field(default=0.0, ge=0, description="Weight used")
    rpe: Optional[int] = Field(None, ge=1, le=10, description="Rate of perceived exertion (1-10)")
    is_completed: bool = Field(default=False, description="Whether the set is completed")
    notes: Optional[str] = Field(None, description="Optional notes")

class CompleteWorkoutRequest(BaseModel):
    duration_seconds: int = Field(..., ge=0, description="Total duration in seconds")
    total_volume: float = Field(..., ge=0, description="Total volume (weight * reps)")
    notes: Optional[str] = Field(None, description="Post-workout notes")

@app.post("/workout-sessions")
async def create_workout_session(
    request: CreateWorkoutSessionRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Create a new workout session."""
    try:
        session_data = {
            "name": request.name,
            "status": "planned",
            "scheduled_date": request.scheduled_date,
            "notes": request.notes or "",
        }
        session = await WorkoutSessionRepository.create_session(current_user["id"], session_data)
        return {
            "success": True,
            "session": session,
            "message": "Workout session created successfully"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/workout-sessions")
async def get_workout_sessions(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get user's workout sessions."""
    try:
        sessions = await WorkoutSessionRepository.get_by_user(current_user["id"], limit, offset)
        return {
            "success": True,
            "sessions": sessions,
            "count": len(sessions)
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/workout-sessions/{session_id}")
async def get_workout_session(
    session_id: str,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get a specific workout session with all details."""
    try:
        session = await WorkoutSessionRepository.get_by_id(session_id, current_user["id"])
        if not session:
            raise HTTPException(status_code=404, detail="Workout session not found")
        return {
            "success": True,
            "session": session
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/workout-sessions/{session_id}/exercises")
async def add_exercise_to_session(
    session_id: str,
    request: AddExerciseEntryRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Add an exercise to a workout session."""
    try:
        # Verify session exists and belongs to user
        session = await WorkoutSessionRepository.get_by_id(session_id, current_user["id"])
        if not session:
            raise HTTPException(status_code=404, detail="Workout session not found")

        exercise_data = {
            "exercise_id": request.exercise_id,
            "exercise_name": request.exercise_name,
            "target_sets": request.target_sets,
            "target_reps": request.target_reps,
            "target_weight": request.target_weight,
            "rest_seconds": request.rest_seconds,
            "notes": request.notes or "",
            "order_index": request.order_index,
        }
        entry = await WorkoutSessionRepository.add_exercise_entry(session_id, exercise_data)
        return {
            "success": True,
            "exercise_entry": entry,
            "message": "Exercise added to session"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/workout-sessions/{session_id}/exercises/{exercise_entry_id}/sets")
async def add_set_to_exercise(
    session_id: str,
    exercise_entry_id: str,
    request: AddSetRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Add a set to an exercise entry."""
    try:
        # Verify session exists and belongs to user
        session = await WorkoutSessionRepository.get_by_id(session_id, current_user["id"])
        if not session:
            raise HTTPException(status_code=404, detail="Workout session not found")

        set_data = {
            "set_number": request.set_number,
            "reps": request.reps,
            "weight": request.weight,
            "rpe": request.rpe,
            "is_completed": request.is_completed,
            "notes": request.notes or "",
        }
        set_entry = await WorkoutSessionRepository.add_set(exercise_entry_id, session_id, set_data)
        return {
            "success": True,
            "set": set_entry,
            "message": "Set added successfully"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/workout-sessions/{session_id}/complete")
async def complete_workout_session(
    session_id: str,
    request: CompleteWorkoutRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Mark a workout session as completed."""
    try:
        # Verify session exists and belongs to user
        session = await WorkoutSessionRepository.get_by_id(session_id, current_user["id"])
        if not session:
            raise HTTPException(status_code=404, detail="Workout session not found")

        completion_data = {
            "duration_seconds": request.duration_seconds,
            "total_volume": request.total_volume,
            "notes": request.notes or "",
        }
        updated_session = await WorkoutSessionRepository.complete_session(session_id, current_user["id"], completion_data)

        # Award XP for completing workout
        xp_data = {
            "xp_amount": calculate_workout_xp(request.duration_seconds, request.total_volume),
            "activity": "Completed workout session",
        }
        await WarriorProfileRepository.add_xp(current_user["id"], xp_data)

        return {
            "success": True,
            "session": updated_session,
            "xp_awarded": xp_data["xp_amount"],
            "message": "Workout completed successfully"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/workout-sessions/{session_id}")
async def delete_workout_session(
    session_id: str,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Delete a workout session."""
    try:
        success = await WorkoutSessionRepository.delete_session(session_id, current_user["id"])
        if not success:
            raise HTTPException(status_code=404, detail="Workout session not found")
        return {
            "success": True,
            "message": "Workout session deleted successfully"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

def calculate_workout_xp(duration_seconds: int, total_volume: float) -> int:
    """Calculate XP awarded for a workout based on duration and volume."""
    base_xp = 50
    duration_bonus = min(duration_seconds // 300, 50)  # +10 XP per 5 minutes, max 50
    volume_bonus = min(int(total_volume / 1000), 50)  # +1 XP per 1000 volume, max 50
    return base_xp + duration_bonus + volume_bonus


# ============== Notification API ==============

@app.get("/notifications")
async def get_notifications(
    limit: int = Query(default=50, ge=1, le=100),
    include_read: bool = Query(default=False),
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get user's notifications."""
    try:
        notifications = await NotificationRepository.get_by_user(current_user["id"], limit, include_read)
        unread_count = await NotificationRepository.get_unread_count(current_user["id"])
        return {
            "success": True,
            "notifications": notifications,
            "unread_count": unread_count
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Mark a notification as read."""
    try:
        notification = await NotificationRepository.mark_as_read(notification_id, current_user["id"])
        return {
            "success": True,
            "notification": notification
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/notifications/read-all")
async def mark_all_notifications_read(
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Mark all notifications as read."""
    try:
        success = await NotificationRepository.mark_all_as_read(current_user["id"])
        return {
            "success": success,
            "message": "All notifications marked as read"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============== Progress Tracking API ==============

class RecordProgressRequest(BaseModel):
    metric_type: str = Field(..., description="Type of metric (weight, body_fat, measurement, etc.)")
    value: float = Field(..., description="Metric value")
    unit: str = Field(default="", description="Unit of measurement")
    notes: Optional[str] = Field(None, description="Optional notes")
    measured_at: Optional[str] = Field(None, description="ISO timestamp when measured")

class RecordPersonalRecordRequest(BaseModel):
    exercise_id: str = Field(..., description="ID of the exercise")
    exercise_name: str = Field(..., description="Name of the exercise")
    metric_type: str = Field(..., description="Type of PR (weight, reps, volume)")
    value: float = Field(..., description="PR value")
    previous_value: Optional[float] = Field(None, description="Previous PR value for comparison")
    improvement_percent: float = Field(default=0.0, description="Percentage improvement")

@app.post("/progress/metrics")
async def record_progress_metric(
    request: RecordProgressRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Record a progress metric (weight, body fat, measurements, etc.)."""
    try:
        metric_data = {
            "metric_type": request.metric_type,
            "value": request.value,
            "unit": request.unit,
            "notes": request.notes or "",
            "measured_at": request.measured_at,
        }
        metric = await ProgressRepository.record_metric(current_user["id"], metric_data)
        return {
            "success": True,
            "metric": metric,
            "message": "Progress metric recorded"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/progress/metrics")
async def get_progress_metrics(
    metric_type: Optional[str] = Query(None, description="Filter by metric type"),
    limit: int = Query(default=100, ge=1, le=500),
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get user's progress metrics."""
    try:
        metrics = await ProgressRepository.get_metrics(current_user["id"], metric_type, limit)
        return {
            "success": True,
            "metrics": metrics,
            "count": len(metrics)
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/progress/personal-records")
async def record_personal_record(
    request: RecordPersonalRecordRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Record a personal record for an exercise."""
    try:
        pr_data = {
            "exercise_id": request.exercise_id,
            "exercise_name": request.exercise_name,
            "metric_type": request.metric_type,
            "value": request.value,
            "previous_value": request.previous_value,
            "improvement_percent": request.improvement_percent,
        }
        pr = await ProgressRepository.record_personal_record(current_user["id"], pr_data)

        # Award bonus XP for PR
        xp_bonus = min(int(request.improvement_percent), 100)
        await WarriorProfileRepository.add_xp(current_user["id"], {
            "xp_amount": 20 + xp_bonus,
            "activity": f"New PR: {request.exercise_name}"
        })

        return {
            "success": True,
            "personal_record": pr,
            "xp_awarded": 20 + xp_bonus,
            "message": "Personal record recorded"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/progress/personal-records")
async def get_personal_records(
    exercise_id: Optional[str] = Query(None, description="Filter by exercise ID"),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get user's personal records."""
    try:
        records = await ProgressRepository.get_personal_records(current_user["id"], exercise_id, limit)
        return {
            "success": True,
            "personal_records": records,
            "count": len(records)
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============== AI Memory Management API ==============

class StoreAIMemoryRequest(BaseModel):
    memory_type: str = Field(..., description="Type of memory (workout_preference, feedback, pattern, etc.)")
    data: Dict[str, Any] = Field(..., description="Memory data")
    priority: str = Field(default="medium", description="Priority: low, medium, high")
    tags: List[str] = Field(default_factory=list, description="Tags for categorization")

@app.post("/ai-memories")
async def store_ai_memory(
    request: StoreAIMemoryRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Store an AI memory for personalized workout generation."""
    try:
        memory = await AIMemoryRepository.store(
            current_user["id"],
            request.memory_type,
            request.data,
            request.priority,
            request.tags
        )
        return {
            "success": True,
            "memory": memory,
            "message": "AI memory stored successfully"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/ai-memories")
async def get_ai_memories(
    memory_type: Optional[str] = Query(None, description="Filter by memory type"),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get AI memories for personalized context."""
    try:
        memories = await AIMemoryRepository.get_by_user(current_user["id"], memory_type, limit)
        return {
            "success": True,
            "memories": memories,
            "count": len(memories)
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============== User Profile Management API ==============

class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = Field(None, description="User's display name")
    bio: Optional[str] = Field(None, description="User bio")
    fitness_goal: Optional[str] = Field(None, description="Primary fitness goal")
    experience_level: Optional[str] = Field(None, description="Experience level (beginner, intermediate, advanced)")
    preferred_workout_duration: Optional[int] = Field(None, ge=10, description="Preferred workout duration in minutes")
    workout_days_per_week: Optional[int] = Field(None, ge=1, le=7, description="Number of workout days per week")

@app.get("/users/profile")
async def get_user_profile(
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get current user's profile."""
    try:
        profile = await UserRepository.get_by_id(current_user["id"])
        if not profile:
            # Create default profile
            profile_data = {
                "display_name": current_user.get("email", "").split("@")[0],
                "bio": "",
                "fitness_goal": "general_fitness",
                "experience_level": "beginner",
            }
            profile = await UserRepository.create_or_update(current_user["id"], profile_data)
        return {
            "success": True,
            "profile": profile
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/users/profile")
async def update_user_profile(
    request: UpdateProfileRequest,
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Update current user's profile."""
    try:
        profile_data = {
            k: v for k, v in request.dict().items() if v is not None
        }
        profile_data["updated_at"] = "now()"
        profile = await UserRepository.create_or_update(current_user["id"], profile_data)
        return {
            "success": True,
            "profile": profile,
            "message": "Profile updated successfully"
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============== Analytics API ==============

@app.get("/analytics/summary")
async def get_analytics_summary(
    days: int = Query(default=30, ge=7, le=365),
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get comprehensive analytics summary for the user."""
    try:
        # Get workout sessions in date range
        from datetime import datetime, timedelta
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        # Fetch sessions
        all_sessions = await WorkoutSessionRepository.get_by_user(current_user["id"], limit=1000)
        recent_sessions = [s for s in all_sessions if s.get("created_at", "") >= cutoff_date]

        # Calculate metrics
        total_workouts = len(recent_sessions)
        completed_workouts = len([s for s in recent_sessions if s.get("status") == "completed"])
        total_volume = sum(s.get("total_volume", 0) for s in recent_sessions)
        total_duration = sum(s.get("duration_seconds", 0) for s in recent_sessions)

        # Get personal records
        recent_prs = await ProgressRepository.get_personal_records(current_user["id"], limit=50)
        recent_prs = [pr for pr in recent_prs if pr.get("achieved_at", "") >= cutoff_date]

        # Get warrior profile for streak info
        warrior_profile = await WarriorProfileRepository.get_by_user_id(current_user["id"])

        return {
            "success": True,
            "period_days": days,
            "summary": {
                "total_workouts": total_workouts,
                "completed_workouts": completed_workouts,
                "completion_rate": round(completed_workouts / total_workouts * 100, 1) if total_workouts > 0 else 0,
                "total_volume": round(total_volume, 2),
                "total_duration_hours": round(total_duration / 3600, 2),
                "average_workout_duration_minutes": round(total_duration / completed_workouts / 60, 1) if completed_workouts > 0 else 0,
                "personal_records_count": len(recent_prs),
                "current_streak_days": warrior_profile.get("current_streak_days", 0) if warrior_profile else 0,
            }
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/analytics/workout-trends")
async def get_workout_trends(
    days: int = Query(default=30, ge=7, le=365),
    current_user: Dict = Depends(get_current_user_supabase)
):
    """Get workout trends over time."""
    try:
        from datetime import datetime, timedelta
        from collections import defaultdict

        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        # Fetch sessions
        all_sessions = await WorkoutSessionRepository.get_by_user(current_user["id"], limit=1000)
        recent_sessions = [s for s in all_sessions if s.get("completed_at") and s.get("completed_at") >= cutoff_date]

        # Group by week
        weekly_data = defaultdict(lambda: {"count": 0, "volume": 0, "duration": 0})
        for session in recent_sessions:
            completed_at = session.get("completed_at", "")
            if completed_at:
                week_key = completed_at[:10]  # YYYY-MM-DD
                weekly_data[week_key]["count"] += 1
                weekly_data[week_key]["volume"] += session.get("total_volume", 0)
                weekly_data[week_key]["duration"] += session.get("duration_seconds", 0)

        # Convert to list
        trends = [
            {
                "week": week,
                "workouts": data["count"],
                "volume": round(data["volume"], 2),
                "duration_hours": round(data["duration"] / 3600, 2),
            }
            for week, data in sorted(weekly_data.items())
        ]

        return {
            "success": True,
            "period_days": days,
            "trends": trends
        }
    except DatabaseError as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
