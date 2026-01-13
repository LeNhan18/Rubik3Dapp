from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict, List, Set
import json
from datetime import datetime

class ConnectionManager:
    """Manages WebSocket connections for real-time communication"""
    def __init__(self):
        # Map user_id -> WebSocket
        self.active_connections: Dict[int, WebSocket] = {}
        # Map user_id -> username
        self.user_usernames: Dict[int, str] = {}
        # Map match_id -> Set[user_id]
        self.match_rooms: Dict[str, Set[int]] = {}
        # Map user_id -> Set[match_id]
        self.user_matches: Dict[int, Set[str]] = {}

    async def connect(self, websocket: WebSocket, user_id: int, username: str = None):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        self.active_connections[user_id] = websocket
        if username:
            self.user_usernames[user_id] = username

    def disconnect(self, user_id: int):
        """Remove a WebSocket connection"""
        if user_id in self.active_connections:
            del self.active_connections[user_id]
        if user_id in self.user_usernames:
            del self.user_usernames[user_id]
        
        # Remove from all match rooms
        if user_id in self.user_matches:
            for match_id in self.user_matches[user_id]:
                if match_id in self.match_rooms:
                    self.match_rooms[match_id].discard(user_id)
                    if not self.match_rooms[match_id]:
                        del self.match_rooms[match_id]
            del self.user_matches[user_id]

    async def join_match(self, user_id: int, match_id: str):
        """Add user to a match room"""
        if match_id not in self.match_rooms:
            self.match_rooms[match_id] = set()
        
        self.match_rooms[match_id].add(user_id)
        
        if user_id not in self.user_matches:
            self.user_matches[user_id] = set()
        self.user_matches[user_id].add(match_id)

    async def leave_match(self, user_id: int, match_id: str):
        """Remove user from a match room"""
        if match_id in self.match_rooms:
            self.match_rooms[match_id].discard(user_id)
            if not self.match_rooms[match_id]:
                del self.match_rooms[match_id]
        
        if user_id in self.user_matches:
            self.user_matches[user_id].discard(match_id)

    async def send_personal_message(self, message: dict, user_id: int):
        """Send a message to a specific user"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_json(message)
            except Exception as e:
                print(f"Error sending message to user {user_id}: {e}")
                self.disconnect(user_id)
    async def broadcast_to_match(self, message: dict, match_id: str, exclude_user_id: int = None):
        """Broadcast a message to all users in a match room"""
        if match_id in self.match_rooms:
            for user_id in self.match_rooms[match_id]:
                if user_id != exclude_user_id:
                    await self.send_personal_message(message, user_id)

    async def handle_message(self, user_id: int, data: dict):
        """Handle incoming WebSocket message"""
        message_type = data.get("type")
        
        if message_type == "chat":
            # Broadcast chat message to match room
            match_id = data.get("match_id")
            if match_id:
                sender_username = self.user_usernames.get(user_id, f"User{user_id}")
                await self.broadcast_to_match({
                    "type": "chat",
                    "match_id": match_id,  # IMPORTANT: Client needs this to filter messages
                    "sender_id": user_id,
                    "sender_username": sender_username,
                    "content": data.get("content", ""),
                    "timestamp": datetime.utcnow().isoformat()
                }, match_id, exclude_user_id=user_id)
        
        elif message_type == "join_match":
            match_id = data.get("match_id")
            if match_id:
                await self.join_match(user_id, match_id)
                await self.send_personal_message({
                    "type": "joined_match",
                    "match_id": match_id
                }, user_id)
        elif message_type == "leave_match":
            match_id = data.get("match_id")
            if match_id:
                await self.leave_match(user_id, match_id)