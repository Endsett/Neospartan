"""Pytest configuration and fixtures."""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


@pytest.fixture
def client():
    """Create a test client."""
    return TestClient(app)


@pytest.fixture
def mock_supabase_auth():
    """Mock Supabase authentication."""
    mock_user = {
        "id": "test-user-id",
        "email": "test@example.com",
        "user_metadata": {"name": "Test User"}
    }
    
    with patch("auth.supabase_client") as mock_client:
        mock_client.auth.get_user.return_value = Mock(user=mock_user)
        yield mock_user


@pytest.fixture
def auth_headers(mock_supabase_auth):
    """Get authentication headers."""
    return {"Authorization": "Bearer test-token"}
