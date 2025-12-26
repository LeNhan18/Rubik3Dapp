from sqlalchemy import Column, Integer, String, Text, Enum, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.database import Base

class MatchStatus(str, enum.Enum):
    waiting = "waiting"
    active = "active"
    completed = "completed"
    cancelled = "cancelled"

class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(String(36), unique=True, nullable=False, index=True)
    player1_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    player2_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    scramble = Column(Text, nullable=False)
    status = Column(Enum(MatchStatus), default=MatchStatus.waiting, nullable=False)
    player1_time = Column(Integer, nullable=True)  # milliseconds
    player2_time = Column(Integer, nullable=True)
    winner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    is_draw = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    player1 = relationship("User", foreign_keys=[player1_id])
    player2 = relationship("User", foreign_keys=[player2_id])
    winner = relationship("User", foreign_keys=[winner_id])

