from sqlalchemy import Column, Integer, Enum, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.database import Base

class FriendshipStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    blocked = "blocked"

class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    user1_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    user2_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    status = Column(Enum(FriendshipStatus), default=FriendshipStatus.pending, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    user1 = relationship("User", foreign_keys=[user1_id])
    user2 = relationship("User", foreign_keys=[user2_id])

    # Unique constraint
    __table_args__ = (
        UniqueConstraint('user1_id', 'user2_id', name='unique_friendship'),
    )

