from sqlalchemy import Column, Integer, String, Text, Enum, DateTime, ForeignKey, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.database import Base

class MessageType(str, enum.Enum):
    text = "text"
    system = "system"

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(String(36), ForeignKey("matches.match_id", ondelete="CASCADE"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    message_type = Column(Enum(MessageType), default=MessageType.text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    sender = relationship("User")
    match = relationship("Match")

    # Indexes
    __table_args__ = (
        Index('idx_match_id', 'match_id'),
        Index('idx_created_at', 'created_at'),
    )

