"""Comprehensive tests for all API endpoints."""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, AsyncMock
import json

# Test data
TEST_USER = {
    "id": "test-user-id",
    "email": "test@example.com"
}

TEST_EXERCISE = {
    "id": "test-exercise-1",
    "name": "Test Exercise",
    "category": "strength",
    "difficulty": "intermediate"
}

TEST_WORKOUT_SESSION = {
    "id": "test-session-1",
    "name": "Test Workout",
    "status": "planned",
    "user_id": "test-user-id"
}


class TestHealthEndpoints:
    """Test health check endpoints."""

    def test_root_endpoint(self, client):
        """Test root endpoint returns API info."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "version" in data

    def test_health_check(self, client):
        """Test basic health check."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data
        assert "timestamp" in data

    def test_detailed_health_check(self, client):
        """Test detailed health check with database status."""
        response = client.get("/health/detailed")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "database" in data
        assert "version" in data


class TestExerciseEndpoints:
    """Test exercise library endpoints."""

    def test_get_all_exercises(self, client):
        """Test getting all exercises."""
        response = client.get("/exercises")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

    def test_get_exercises_by_category(self, client):
        """Test filtering exercises by category."""
        response = client.get("/exercises?category=strength")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for exercise in data:
            assert exercise["category"] == "strength"

    def test_get_single_exercise(self, client):
        """Test getting a specific exercise."""
        response = client.get("/exercises/bench_press")
        assert response.status_code == 200
        data = response.json()
        assert "id" in data
        assert "name" in data
        assert "category" in data

    def test_get_exercise_not_found(self, client):
        """Test 404 for non-existent exercise."""
        response = client.get("/exercises/nonexistent")
        assert response.status_code == 404

    @patch("database.ExerciseRepository.get_for_user", new_callable=AsyncMock)
    def test_get_exercises_dynamic(self, mock_repo, client, auth_headers):
        """Test dynamic exercise fetching."""
        mock_repo.return_value = [TEST_EXERCISE]
        response = client.get("/exercises/dynamic", headers=auth_headers)
        assert response.status_code == 200


class TestAIEndpoints:
    """Test AI-powered workout generation."""

    @patch("main.GeminiAIEngine.generate_workout", new_callable=AsyncMock)
    def test_ai_generate_workout(self, mock_generate, client, auth_headers):
        """Test AI workout generation endpoint."""
        mock_generate.return_value = {
            "protocol": {
                "name": "AI Workout",
                "exercises": [{"name": "Push Ups", "sets": 3, "reps": 12}]
            },
            "ai_generated": True,
            "fallback_used": False
        }
        
        request_data = {
            "readiness_score": 80,
            "goal": "strength",
            "time_limit": 30,
            "focus": "upper"
        }
        response = client.post("/ai/workout/generate", json=request_data, headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "protocol" in data
        assert "ai_generated" in data


class TestDOMRLEndpoints:
    """Test DOM-RL rule-based engine endpoints."""

    def test_optimize_with_domrl(self, client):
        """Test DOM-RL optimization."""
        request_data = {
            "readiness_score": 75,
            "sleep_quality": 7,
            "stress_level": 3,
            "workouts_this_week": 3,
            "last_workout_intensity": 7,
            "joint_discomfort": {"knees": 2, "shoulders": 1}
        }
        base_protocol = {
            "name": "Base Protocol",
            "exercises": [{"name": "Squats", "sets": 3, "reps": 10}]
        }
        response = client.post("/dom-rl/optimize", json={
            "micro_cycle": request_data,
            "base_protocol": base_protocol
        })
        assert response.status_code == 200
        data = response.json()
        assert "protocol" in data
        assert "optimization_applied" in data

    def test_ephor_scrutiny(self, client):
        """Test weekly review analysis."""
        response = client.post("/ephor-scrutiny/analyze", json={
            "readiness_score": 80,
            "sleep_quality": 7,
            "stress_level": 3,
            "workouts_this_week": 4
        })
        assert response.status_code == 200
        data = response.json()
        assert "analysis" in data
        assert "score" in data

    def test_realtime_adaptation(self, client):
        """Test real-time workout adaptation."""
        response = client.post("/realtime-adaptation", json={
            "current_state": {"readiness_score": 75},
            "performed_protocol": {"exercises": []}
        })
        assert response.status_code == 200


class TestStoicEndpoints:
    """Test Stoic philosophy endpoints."""

    def test_get_stoic_primer(self, client):
        """Test getting Stoic primer."""
        response = client.get("/stoic/primer")
        assert response.status_code == 200
        data = response.json()
        assert "quote" in data
        assert "metaphor" in data
        assert "focus_prompt" in data

    def test_get_flow_prompts(self, client):
        """Test getting flow tracking prompts."""
        response = client.get("/stoic/flow-prompts")
        assert response.status_code == 200
        data = response.json()
        assert "pre_workout" in data
        assert "post_workout" in data


class TestArmorAnalyticsEndpoints:
    """Test armor analytics endpoints."""

    def test_armor_analytics(self, client):
        """Test joint/muscle load analysis."""
        response = client.post("/armor-analytics/analyze", json={
            "readiness_score": 80,
            "workouts_this_week": 3
        })
        assert response.status_code == 200
        data = response.json()
        assert "risk_flags" in data
        assert "summary" in data

    def test_tactical_retreat_check(self, client):
        """Test tactical retreat check."""
        response = client.post("/tactical-retreat/check", json={
            "current_readiness": 40,
            "joint_stress": {"knees": 8, "lower_back": 7}
        })
        assert response.status_code == 200
        data = response.json()
        assert "recommended_action" in data


class TestProtocolEndpoints:
    """Test protocol generation endpoints."""

    def test_get_base_protocol(self, client):
        """Test getting base protocol for tier."""
        response = client.get("/protocols/base/recruit")
        assert response.status_code == 200
        data = response.json()
        assert "name" in data
        assert "exercises" in data

    def test_generate_protocol(self, client):
        """Test generating protocol by readiness score."""
        response = client.get("/protocols/generate/85")
        assert response.status_code == 200
        data = response.json()
        assert "protocol" in data
        assert "generated_for_readiness" in data


class TestWarriorProgressionEndpoints:
    """Test warrior progression endpoints."""

    @patch("database.WarriorProfileRepository.get_by_user_id", new_callable=AsyncMock)
    def test_get_warrior_profile(self, mock_repo, client, auth_headers):
        """Test getting warrior profile."""
        mock_repo.return_value = {
            "user_id": "test-user-id",
            "level": 1,
            "xp": 100,
            "rank_name": "Helot"
        }
        response = client.get("/warrior/profile", headers=auth_headers)
        assert response.status_code == 200

    @patch("database.WarriorProfileRepository.add_xp", new_callable=AsyncMock)
    def test_add_warrior_xp(self, mock_add_xp, client, auth_headers):
        """Test adding XP to warrior."""
        mock_add_xp.return_value = {
            "level": 2,
            "xp": 150,
            "leveled_up": True
        }
        response = client.post("/warrior/xp", json={
            "xp_amount": 50,
            "activity": "Completed workout"
        }, headers=auth_headers)
        assert response.status_code == 200

    def test_get_warrior_ranks(self, client):
        """Test getting all warrior ranks."""
        response = client.get("/warrior/ranks")
        assert response.status_code == 200
        data = response.json()
        assert "ranks" in data
        assert len(data["ranks"]) == 10

    @patch("database.AchievementRepository.get_all", new_callable=AsyncMock)
    @patch("database.WarriorProfileRepository.get_by_user_id", new_callable=AsyncMock)
    def test_get_warrior_achievements(self, mock_profile, mock_achievements, client, auth_headers):
        """Test getting warrior achievements."""
        mock_profile.return_value = {"achievements": []}
        mock_achievements.return_value = []
        response = client.get("/warrior/achievements", headers=auth_headers)
        assert response.status_code == 200


class TestWorkoutSessionEndpoints:
    """Test workout session management endpoints."""

    @patch("database.WorkoutSessionRepository.create_session", new_callable=AsyncMock)
    def test_create_workout_session(self, mock_create, client, auth_headers):
        """Test creating workout session."""
        mock_create.return_value = TEST_WORKOUT_SESSION
        response = client.post("/workout-sessions", json={
            "name": "Test Workout",
            "notes": "Test notes"
        }, headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "session" in data

    @patch("database.WorkoutSessionRepository.get_by_user", new_callable=AsyncMock)
    def test_get_workout_sessions(self, mock_get, client, auth_headers):
        """Test getting user's workout sessions."""
        mock_get.return_value = [TEST_WORKOUT_SESSION]
        response = client.get("/workout-sessions", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "sessions" in data

    @patch("database.WorkoutSessionRepository.get_by_id", new_callable=AsyncMock)
    def test_get_workout_session_detail(self, mock_get, client, auth_headers):
        """Test getting specific workout session."""
        mock_get.return_value = TEST_WORKOUT_SESSION
        response = client.get("/workout-sessions/test-session-1", headers=auth_headers)
        assert response.status_code == 200

    @patch("database.WorkoutSessionRepository.get_by_id", new_callable=AsyncMock)
    @patch("database.WorkoutSessionRepository.add_exercise_entry", new_callable=AsyncMock)
    def test_add_exercise_to_session(self, mock_add, mock_get, client, auth_headers):
        """Test adding exercise to session."""
        mock_get.return_value = TEST_WORKOUT_SESSION
        mock_add.return_value = {"id": "entry-1", "exercise_name": "Squats"}
        response = client.post("/workout-sessions/test-session-1/exercises", json={
            "exercise_id": "squat-1",
            "exercise_name": "Squats",
            "target_sets": 3,
            "target_reps": 10
        }, headers=auth_headers)
        assert response.status_code == 200

    @patch("database.WorkoutSessionRepository.get_by_id", new_callable=AsyncMock)
    @patch("database.WorkoutSessionRepository.complete_session", new_callable=AsyncMock)
    @patch("database.WarriorProfileRepository.add_xp", new_callable=AsyncMock)
    def test_complete_workout_session(self, mock_xp, mock_complete, mock_get, client, auth_headers):
        """Test completing workout session."""
        mock_get.return_value = TEST_WORKOUT_SESSION
        mock_complete.return_value = {**TEST_WORKOUT_SESSION, "status": "completed"}
        mock_xp.return_value = None
        response = client.post("/workout-sessions/test-session-1/complete", json={
            "duration_seconds": 3600,
            "total_volume": 5000
        }, headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "xp_awarded" in data


class TestNotificationEndpoints:
    """Test notification endpoints."""

    @patch("database.NotificationRepository.get_by_user", new_callable=AsyncMock)
    @patch("database.NotificationRepository.get_unread_count", new_callable=AsyncMock)
    def test_get_notifications(self, mock_count, mock_get, client, auth_headers):
        """Test getting notifications."""
        mock_get.return_value = []
        mock_count.return_value = 0
        response = client.get("/notifications", headers=auth_headers)
        assert response.status_code == 200

    @patch("database.NotificationRepository.mark_as_read", new_callable=AsyncMock)
    def test_mark_notification_read(self, mock_mark, client, auth_headers):
        """Test marking notification as read."""
        mock_mark.return_value = {"id": "notif-1", "is_read": True}
        response = client.post("/notifications/notif-1/read", headers=auth_headers)
        assert response.status_code == 200

    @patch("database.NotificationRepository.mark_all_as_read", new_callable=AsyncMock)
    def test_mark_all_notifications_read(self, mock_mark, client, auth_headers):
        """Test marking all notifications as read."""
        mock_mark.return_value = True
        response = client.post("/notifications/read-all", headers=auth_headers)
        assert response.status_code == 200


class TestProgressEndpoints:
    """Test progress tracking endpoints."""

    @patch("database.ProgressRepository.record_metric", new_callable=AsyncMock)
    def test_record_progress_metric(self, mock_record, client, auth_headers):
        """Test recording progress metric."""
        mock_record.return_value = {"id": "metric-1", "value": 75.5}
        response = client.post("/progress/metrics", json={
            "metric_type": "weight",
            "value": 75.5,
            "unit": "kg"
        }, headers=auth_headers)
        assert response.status_code == 200

    @patch("database.ProgressRepository.get_metrics", new_callable=AsyncMock)
    def test_get_progress_metrics(self, mock_get, client, auth_headers):
        """Test getting progress metrics."""
        mock_get.return_value = []
        response = client.get("/progress/metrics", headers=auth_headers)
        assert response.status_code == 200

    @patch("database.ProgressRepository.record_personal_record", new_callable=AsyncMock)
    @patch("database.WarriorProfileRepository.add_xp", new_callable=AsyncMock)
    def test_record_personal_record(self, mock_xp, mock_record, client, auth_headers):
        """Test recording personal record."""
        mock_record.return_value = {"id": "pr-1", "value": 100}
        mock_xp.return_value = None
        response = client.post("/progress/personal-records", json={
            "exercise_id": "bench-1",
            "exercise_name": "Bench Press",
            "metric_type": "weight",
            "value": 100
        }, headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "xp_awarded" in data


class TestAIMemoryEndpoints:
    """Test AI memory endpoints."""

    @patch("database.AIMemoryRepository.store", new_callable=AsyncMock)
    def test_store_ai_memory(self, mock_store, client, auth_headers):
        """Test storing AI memory."""
        mock_store.return_value = {"id": "memory-1"}
        response = client.post("/ai-memories", json={
            "memory_type": "workout_preference",
            "data": {"preferred_time": "morning"},
            "priority": "high",
            "tags": ["preference"]
        }, headers=auth_headers)
        assert response.status_code == 200

    @patch("database.AIMemoryRepository.get_by_user", new_callable=AsyncMock)
    def test_get_ai_memories(self, mock_get, client, auth_headers):
        """Test getting AI memories."""
        mock_get.return_value = []
        response = client.get("/ai-memories", headers=auth_headers)
        assert response.status_code == 200


class TestUserProfileEndpoints:
    """Test user profile endpoints."""

    @patch("database.UserRepository.get_by_id", new_callable=AsyncMock)
    def test_get_user_profile(self, mock_get, client, auth_headers):
        """Test getting user profile."""
        mock_get.return_value = {
            "id": "test-user-id",
            "display_name": "Test User",
            "fitness_goal": "strength"
        }
        response = client.get("/users/profile", headers=auth_headers)
        assert response.status_code == 200

    @patch("database.UserRepository.create_or_update", new_callable=AsyncMock)
    def test_update_user_profile(self, mock_update, client, auth_headers):
        """Test updating user profile."""
        mock_update.return_value = {
            "id": "test-user-id",
            "display_name": "Updated Name"
        }
        response = client.put("/users/profile", json={
            "display_name": "Updated Name",
            "bio": "New bio"
        }, headers=auth_headers)
        assert response.status_code == 200


class TestAnalyticsEndpoints:
    """Test analytics endpoints."""

    @patch("database.WorkoutSessionRepository.get_by_user", new_callable=AsyncMock)
    @patch("database.ProgressRepository.get_personal_records", new_callable=AsyncMock)
    @patch("database.WarriorProfileRepository.get_by_user_id", new_callable=AsyncMock)
    def test_get_analytics_summary(self, mock_warrior, mock_prs, mock_sessions, client, auth_headers):
        """Test getting analytics summary."""
        mock_sessions.return_value = []
        mock_prs.return_value = []
        mock_warrior.return_value = {"current_streak_days": 5}
        response = client.get("/analytics/summary?days=30", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "summary" in data

    @patch("database.WorkoutSessionRepository.get_by_user", new_callable=AsyncMock)
    def test_get_workout_trends(self, mock_get, client, auth_headers):
        """Test getting workout trends."""
        mock_get.return_value = []
        response = client.get("/analytics/workout-trends?days=30", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "trends" in data


class TestWebSocket:
    """Test WebSocket endpoint."""

    def test_websocket_endpoint(self, client):
        """Test WebSocket connection."""
        # Note: Full WebSocket testing requires more setup
        # This is a basic connectivity test
        with client.websocket_connect("/ws/workout/test-user-id") as websocket:
            # Connection should be established
            pass


class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_unauthorized_access(self, client):
        """Test 401 for unauthorized requests."""
        response = client.get("/workout-sessions")
        assert response.status_code == 403  # FastAPI returns 403 for missing auth

    def test_not_found(self, client):
        """Test 404 for non-existent endpoints."""
        response = client.get("/nonexistent-endpoint")
        assert response.status_code == 404

    @patch("database.WorkoutSessionRepository.get_by_id", new_callable=AsyncMock)
    def test_session_not_found(self, mock_get, client, auth_headers):
        """Test 404 for non-existent session."""
        mock_get.return_value = None
        response = client.get("/workout-sessions/fake-id", headers=auth_headers)
        assert response.status_code == 404
