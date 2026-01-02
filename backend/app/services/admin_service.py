from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.user import User
from app.models.match import Match
from app.models.chat_message import ChatMessage
from app.models.friendship import Friendship
from typing import List, Dict, Optional
from datetime import datetime, timedelta

class AdminService:
    def __init__(self, db: Session):
        self.db = db

    # ========== USER MANAGEMENT ==========
    def get_all_users(self, limit: int = 100, offset: int = 0) -> List[User]:
        """Get all users with pagination"""
        return self.db.query(User).offset(offset).limit(limit).all()

    def get_user_count(self) -> int:
        """Get total user count"""
        return self.db.query(User).count()

    def get_user_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return self.db.query(User).filter(User.id == user_id).first()

    def delete_user(self, user_id: int) -> bool:
        """Delete a user (cascade will handle related data)"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        self.db.delete(user)
        self.db.commit()
        return True

    def toggle_admin(self, user_id: int) -> User:
        """Toggle admin status for a user"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user.is_admin = not user.is_admin
        self.db.commit()
        self.db.refresh(user)
        return user

    def ban_user(self, user_id: int) -> User:
        """Ban a user (set is_online to False and update last_seen)"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user.is_online = False
        user.last_seen = datetime.utcnow()
        self.db.commit()
        self.db.refresh(user)
        return user

    # ========== MATCH MANAGEMENT ==========
    def get_all_matches(self, limit: int = 100, offset: int = 0, status_filter: Optional[str] = None) -> List[Match]:
        """Get all matches with optional status filter"""
        query = self.db.query(Match)
        if status_filter:
            query = query.filter(Match.status == status_filter)
        return query.order_by(Match.created_at.desc()).offset(offset).limit(limit).all()

    def get_match_count(self, status_filter: Optional[str] = None) -> int:
        """Get total match count"""
        query = self.db.query(Match)
        if status_filter:
            query = query.filter(Match.status == status_filter)
        return query.count()

    def get_match_by_id(self, match_id: str) -> Optional[Match]:
        """Get match by match_id"""
        return self.db.query(Match).filter(Match.match_id == match_id).first()

    def delete_match(self, match_id: str) -> bool:
        """Delete a match (cascade will handle related messages)"""
        match = self.db.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        self.db.delete(match)
        self.db.commit()
        return True

    # ========== MESSAGE MANAGEMENT ==========
    def get_all_messages(self, limit: int = 100, offset: int = 0, match_id: Optional[str] = None) -> List[ChatMessage]:
        """Get all messages with optional match filter"""
        query = self.db.query(ChatMessage)
        if match_id:
            query = query.filter(ChatMessage.match_id == match_id)
        return query.order_by(ChatMessage.created_at.desc()).offset(offset).limit(limit).all()

    def get_message_count(self, match_id: Optional[str] = None) -> int:
        """Get total message count"""
        query = self.db.query(ChatMessage)
        if match_id:
            query = query.filter(ChatMessage.match_id == match_id)
        return query.count()

    def delete_message(self, message_id: int) -> bool:
        """Delete a message"""
        message = self.db.query(ChatMessage).filter(ChatMessage.id == message_id).first()
        if not message:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Message not found"
            )
        
        self.db.delete(message)
        self.db.commit()
        return True

    # ========== STATISTICS ==========
    def get_statistics(self) -> Dict:
        """Get system statistics"""
        total_users = self.db.query(User).count()
        online_users = self.db.query(User).filter(User.is_online == True).count()
        admin_users = self.db.query(User).filter(User.is_admin == True).count()
        
        total_matches = self.db.query(Match).count()
        active_matches = self.db.query(Match).filter(Match.status == 'active').count()
        completed_matches = self.db.query(Match).filter(Match.status == 'completed').count()
        
        total_messages = self.db.query(ChatMessage).count()
        total_friendships = self.db.query(Friendship).filter(Friendship.status == 'accepted').count()
        
        # Recent activity (last 24 hours)
        yesterday = datetime.utcnow() - timedelta(days=1)
        recent_users = self.db.query(User).filter(User.created_at >= yesterday).count()
        recent_matches = self.db.query(Match).filter(Match.created_at >= yesterday).count()
        recent_messages = self.db.query(ChatMessage).filter(ChatMessage.created_at >= yesterday).count()
        
        return {
            "users": {
                "total": total_users,
                "online": online_users,
                "admins": admin_users,
                "recent_24h": recent_users
            },
            "matches": {
                "total": total_matches,
                "active": active_matches,
                "completed": completed_matches,
                "recent_24h": recent_matches
            },
            "messages": {
                "total": total_messages,
                "recent_24h": recent_messages
            },
            "friendships": {
                "total": total_friendships
            }
        }

