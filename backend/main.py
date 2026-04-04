<<<<<<< C:/Users/cy569/Desktop/Neospartan/backend/main.py
# NeoSpartan AI Backend - DOM-RL Engine
# FastAPI server for workout optimization and AI recommendations

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional, Tuple
from datetime import datetime, timedelta
from enum import Enum
import numpy as np
from dataclasses import dataclass, field
import json

app = FastAPI(title="NeoSpartan AI", version="1.0.0")

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

@app.get("/")
def root():
    return {"message": "NeoSpartan AI Engine - DOM-RL Active", "version": "1.0.0"}

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
=======
# NeoSpartan AI Backend - DOM-RL Engine
# FastAPI server for workout optimization and AI recommendations

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional, Tuple
from datetime import datetime, timedelta
from enum import Enum
import numpy as np
from dataclasses import dataclass, field
import json
import os

app = FastAPI(title="NeoSpartan AI", version="2.0.0")

# CORS configuration
CORS_ORIGINS = os.getenv('CORS_ORIGINS', 'http://localhost:3000,https://neospartan.app').split(',')
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Trusted host middleware
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'api.neospartan.ai,localhost').split(',')
app.add_middleware(TrustedHostMiddleware, allowed_hosts=ALLOWED_HOSTS)

# Simple rate limiting storage
request_counts: Dict[str, List[datetime]] = {}
RATE_LIMIT = int(os.getenv('RATE_LIMIT', '100'))  # requests per minute

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
>>>>>>> C:/Users/cy569/.windsurf/worktrees/Neospartan/Neospartan-3a3e7f8d/backend/main.py
