"""WebSocket connection manager for real-time features."""

import json
from typing import Dict, List, Optional
from datetime import datetime

from fastapi import WebSocket


class ConnectionManager:
    """Manages WebSocket connections."""
    
    def __init__(self):
        # user_id -> List[WebSocket]
        self.active_connections: Dict[str, List[WebSocket]] = {}
        # websocket -> user_id mapping for cleanup
        self.connection_users: Dict[WebSocket, str] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        """Accept and store a new connection."""
        await websocket.accept()
        
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        
        self.active_connections[user_id].append(websocket)
        self.connection_users[websocket] = user_id
    
    def disconnect(self, websocket: WebSocket):
        """Remove a disconnected websocket."""
        user_id = self.connection_users.get(websocket)
        if user_id:
            if user_id in self.active_connections:
                self.active_connections[user_id] = [
                    ws for ws in self.active_connections[user_id] 
                    if ws != websocket
                ]
                if not self.active_connections[user_id]:
                    del self.active_connections[user_id]
            
            del self.connection_users[websocket]
    
    async def send_to_user(self, user_id: str, message: Dict):
        """Send message to all connections of a specific user."""
        if user_id not in self.active_connections:
            return
        
        disconnected = []
        for websocket in self.active_connections[user_id]:
            try:
                await websocket.send_json(message)
            except Exception:
                disconnected.append(websocket)
        
        # Clean up disconnected websockets
        for websocket in disconnected:
            self.disconnect(websocket)
    
    async def send_to_all(self, message: Dict):
        """Broadcast message to all connected users."""
        disconnected = []
        
        for user_id, connections in self.active_connections.items():
            for websocket in connections:
                try:
                    await websocket.send_json(message)
                except Exception:
                    disconnected.append(websocket)
        
        # Clean up disconnected websockets
        for websocket in disconnected:
            self.disconnect(websocket)
    
    async def send_workout_update(self, user_id: str, workout_data: Dict):
        """Send workout generation progress/update to user."""
        await self.send_to_user(user_id, {
            "type": "workout_update",
            "timestamp": datetime.utcnow().isoformat(),
            "data": workout_data
        })
    
    async def send_ai_progress(self, user_id: str, chunk: str):
        """Send AI generation progress (streaming)."""
        await self.send_to_user(user_id, {
            "type": "ai_progress",
            "timestamp": datetime.utcnow().isoformat(),
            "chunk": chunk
        })
    
    async def send_notification(self, user_id: str, title: str, message: str, 
                                notification_type: str = "info"):
        """Send notification to user."""
        await self.send_to_user(user_id, {
            "type": "notification",
            "timestamp": datetime.utcnow().isoformat(),
            "notification": {
                "title": title,
                "message": message,
                "type": notification_type
            }
        })
    
    def get_user_connections(self, user_id: str) -> List[WebSocket]:
        """Get all active connections for a user."""
        return self.active_connections.get(user_id, [])
    
    def is_user_online(self, user_id: str) -> bool:
        """Check if user has any active connections."""
        return user_id in self.active_connections and len(self.active_connections[user_id]) > 0
    
    def get_online_users_count(self) -> int:
        """Get total number of unique online users."""
        return len(self.active_connections)
    
    def get_total_connections(self) -> int:
        """Get total number of active connections."""
        return sum(len(conns) for conns in self.active_connections.values())


# Global connection manager instance
manager = ConnectionManager()
