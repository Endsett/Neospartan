"""Tests for NeoSpartan Backend."""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch

# Import after ensuring we're in the right directory
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from main import app


client = TestClient(app)


def test_health_endpoint():
    """Test basic health check."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"] == "operational"


def test_get_exercises():
    """Test exercises endpoint."""
    response = client.get("/exercises")
    assert response.status_code == 200
    data = response.json()
    assert "exercises" in data
    assert len(data["exercises"]) > 0


def test_get_base_protocol_elite():
    """Test base protocol generation for elite tier."""
    response = client.get("/protocols/base/elite")
    assert response.status_code == 200
    data = response.json()
    assert data["tier"] == "elite"
    assert "entries" in data


def test_generate_protocol():
    """Test protocol generation with readiness score."""
    response = client.get("/protocols/generate/85")
    assert response.status_code == 200
    data = response.json()
    assert "protocol" in data
    assert "optimization_applied" in data


def test_dom_rl_optimize():
    """Test DOM-RL optimization endpoint."""
    test_data = {
        "user_id": "test-user-123",
        "micro_cycle": [
            {
                "date": "2024-01-01",
                "readiness_score": 85,
                "rpe_entries": [8, 9],
                "joint_fatigue": {"knees": 3, "back": 2}
            }
        ]
    }
    response = client.post("/dom-rl/optimize", json=test_data)
    assert response.status_code == 200
    data = response.json()
    assert "state" in data
    assert "action" in data
    assert "protocol" in data


def test_ephor_scrutiny():
    """Test weekly analysis endpoint."""
    test_data = {
        "week_start": "2024-01-01",
        "daily_logs": [
            {
                "date": "2024-01-01",
                "rpe_entries": [8, 9],
                "readiness_score": 85,
                "joint_fatigue": {}
            }
        ]
    }
    response = client.post("/ephor-scrutiny/analyze", json=test_data)
    assert response.status_code == 200
    data = response.json()
    assert "verdict" in data
    assert "fatigue_analysis" in data


def test_stoic_primer():
    """Test stoic primer endpoint."""
    response = client.get("/stoic/primer")
    assert response.status_code == 200
    data = response.json()
    assert "quote" in data
    assert "metaphor" in data
    assert "technique" in data


def test_tactical_retreat():
    """Test tactical retreat check."""
    test_data = {
        "readiness_score": 35,
        "avg_rpe": 9,
        "pain_reports": ["shoulder"],
        "sleep_hours": 4
    }
    response = client.post("/tactical-retreat/check", json=test_data)
    assert response.status_code == 200
    data = response.json()
    assert "should_retreat" in data
    assert "retreat_duration" in data


# Authentication-required tests (will fail without token)
def test_ai_workout_generate_requires_auth():
    """Test that AI workout generation requires authentication."""
    test_data = {
        "fitness_level": "intermediate",
        "training_goal": "strength",
        "preferred_duration": 45
    }
    response = client.post("/ai/workout/generate", json=test_data)
    # Should return 401 or 403 without auth token
    assert response.status_code in [401, 403, 422]


def test_exercises_dynamic_requires_auth():
    """Test that dynamic exercises endpoint requires authentication."""
    response = client.get("/exercises/dynamic")
    # Should return 401 or 403 without auth token
    assert response.status_code in [401, 403]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
