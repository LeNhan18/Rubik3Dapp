from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.chat_message import ChatMessage, MessageType
from app.models.match import Match
from app.schemas.chat import ChatMessageCreate
from datetime import datetime

class ChatService:
    def __init__(self, db: Session):
        self.db = db

    def send_message(self, user_id: int, message_data: ChatMessageCreate) -> ChatMessage:
        """Send a chat message in a match"""
        # Verify match exists and user is a participant
        match = self.db.query(Match).filter(Match.match_id == message_data.match_id).first()
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        if user_id not in [match.player1_id, match.player2_id]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not a participant in this match"
            )
        
        # Create message
        message = ChatMessage(
            match_id=message_data.match_id,
            sender_id=user_id,
            content=message_data.content,
            message_type=MessageType(message_data.message_type)
        )
        
        self.db.add(message)
        self.db.commit()
        self.db.refresh(message)
        
        return message

    def get_messages(self, match_id: str, limit: int = 50, offset: int = 0) -> list[ChatMessage]:
        """Get chat messages for a match"""
        messages = self.db.query(ChatMessage).filter(
            ChatMessage.match_id == match_id
        ).order_by(ChatMessage.created_at.desc()).limit(limit).offset(offset).all()
        
        return list(reversed(messages))  # Return in chronological order

