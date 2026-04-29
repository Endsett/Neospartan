"""Input validation and sanitization utilities."""

import re
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, validator, Field
import bleach


class ValidationError(Exception):
    """Custom validation error."""
    pass


class InputValidator:
    """Input validation and sanitization utilities."""
    
    @staticmethod
    def sanitize_string(value: str, max_length: int = 500) -> str:
        """Sanitize a string input."""
        if not value:
            return ""
        
        # Strip HTML tags
        value = bleach.clean(value, tags=[], strip=True)
        
        # Trim whitespace
        value = value.strip()
        
        # Limit length
        value = value[:max_length]
        
        return value
    
    @staticmethod
    def validate_email(email: str) -> bool:
        """Validate email format."""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    @staticmethod
    def validate_uuid(value: str) -> bool:
        """Validate UUID format."""
        pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        return bool(re.match(pattern, value, re.IGNORECASE))
    
    @staticmethod
    def validate_date_string(date_str: str) -> bool:
        """Validate ISO date string."""
        try:
            datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            return True
        except ValueError:
            return False
    
    @staticmethod
    def validate_metric_type(value: str) -> bool:
        """Validate progress metric type."""
        valid_types = ['weight', 'body_fat', 'measurement', 'custom']
        return value in valid_types
    
    @staticmethod
    def validate_exercise_category(value: str) -> bool:
        """Validate exercise category."""
        valid_categories = [
            'strength', 'cardio', 'flexibility', 'balance', 
            'power', 'endurance', 'mobility'
        ]
        return value in valid_categories
    
    @staticmethod
    def validate_rpe(value: int) -> bool:
        """Validate RPE (Rate of Perceived Exertion) value."""
        return 1 <= value <= 10
    
    @staticmethod
    def validate_workout_status(value: str) -> bool:
        """Validate workout session status."""
        valid_statuses = ['planned', 'in_progress', 'completed', 'cancelled']
        return value in valid_statuses
    
    @staticmethod
    def validate_priority(value: str) -> bool:
        """Validate AI memory priority."""
        return value in ['low', 'medium', 'high']


# Pydantic models with validation

class SanitizedString(BaseModel):
    """String field with automatic sanitization."""
    value: str
    
    @validator('value')
    def sanitize(cls, v):
        return InputValidator.sanitize_string(v)


class ValidatedEmail(BaseModel):
    """Email field with validation."""
    email: str
    
    @validator('email')
    def validate_email(cls, v):
        if not InputValidator.validate_email(v):
            raise ValueError('Invalid email format')
        return v.lower()


class WorkoutSessionValidator(BaseModel):
    """Workout session request validator."""
    name: str = Field(..., min_length=1, max_length=100)
    notes: Optional[str] = Field(None, max_length=1000)
    scheduled_date: Optional[str] = None
    
    @validator('name')
    def sanitize_name(cls, v):
        return InputValidator.sanitize_string(v, max_length=100)
    
    @validator('notes')
    def sanitize_notes(cls, v):
        if v:
            return InputValidator.sanitize_string(v, max_length=1000)
        return v
    
    @validator('scheduled_date')
    def validate_date(cls, v):
        if v and not InputValidator.validate_date_string(v):
            raise ValueError('Invalid date format')
        return v


class ExerciseEntryValidator(BaseModel):
    """Exercise entry validator."""
    exercise_id: str = Field(..., min_length=1, max_length=100)
    exercise_name: str = Field(..., min_length=1, max_length=100)
    target_sets: int = Field(default=3, ge=1, le=20)
    target_reps: int = Field(default=10, ge=1, le=100)
    target_weight: float = Field(default=0.0, ge=0, le=500)
    rest_seconds: int = Field(default=60, ge=0, le=600)
    notes: Optional[str] = Field(None, max_length=500)
    
    @validator('exercise_name')
    def sanitize_name(cls, v):
        return InputValidator.sanitize_string(v, max_length=100)
    
    @validator('notes')
    def sanitize_notes(cls, v):
        if v:
            return InputValidator.sanitize_string(v, max_length=500)
        return v


class SetValidator(BaseModel):
    """Workout set validator."""
    set_number: int = Field(..., ge=1, le=50)
    reps: int = Field(default=0, ge=0, le=100)
    weight: float = Field(default=0.0, ge=0, le=2000)
    rpe: Optional[int] = Field(None, ge=1, le=10)
    notes: Optional[str] = Field(None, max_length=200)
    
    @validator('notes')
    def sanitize_notes(cls, v):
        if v:
            return InputValidator.sanitize_string(v, max_length=200)
        return v


class ProgressMetricValidator(BaseModel):
    """Progress metric validator."""
    metric_type: str = Field(...)
    value: float = Field(...)
    unit: str = Field(default="", max_length=20)
    notes: Optional[str] = Field(None, max_length=500)
    
    @validator('metric_type')
    def validate_type(cls, v):
        if not InputValidator.validate_metric_type(v):
            raise ValueError(f'Invalid metric type. Must be one of: weight, body_fat, measurement, custom')
        return v
    
    @validator('unit')
    def sanitize_unit(cls, v):
        return InputValidator.sanitize_string(v, max_length=20)
    
    @validator('notes')
    def sanitize_notes(cls, v):
        if v:
            return InputValidator.sanitize_string(v, max_length=500)
        return v


class AIMemoryValidator(BaseModel):
    """AI memory validator."""
    memory_type: str = Field(..., max_length=50)
    priority: str = Field(default="medium")
    tags: List[str] = Field(default_factory=list)
    
    @validator('memory_type')
    def sanitize_type(cls, v):
        return InputValidator.sanitize_string(v, max_length=50)
    
    @validator('priority')
    def validate_priority(cls, v):
        if not InputValidator.validate_priority(v):
            raise ValueError('Priority must be low, medium, or high')
        return v
    
    @validator('tags')
    def validate_tags(cls, v):
        return [InputValidator.sanitize_string(tag, max_length=50) for tag in v[:10]]


def sanitize_dict(data: dict, allowed_fields: List[str], max_length: int = 500) -> dict:
    """Sanitize dictionary values."""
    sanitized = {}
    for key, value in data.items():
        if key in allowed_fields:
            if isinstance(value, str):
                sanitized[key] = InputValidator.sanitize_string(value, max_length)
            elif isinstance(value, dict):
                sanitized[key] = sanitize_dict(value, allowed_fields, max_length)
            elif isinstance(value, list):
                sanitized[key] = [
                    InputValidator.sanitize_string(item, max_length) 
                    if isinstance(item, str) else item
                    for item in value
                ]
            else:
                sanitized[key] = value
    return sanitized
