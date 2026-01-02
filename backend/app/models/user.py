from sqlalchemy import Column, Integer, String, Boolean, DateTime, DECIMAL
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.role import user_roles

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    avatar_url = Column(String(255), nullable=True)
    total_wins = Column(Integer, default=0)
    total_losses = Column(Integer, default=0)
    total_draws = Column(Integer, default=0)
    average_time = Column(DECIMAL(10, 2), nullable=True)
    best_time = Column(Integer, nullable=True)  # milliseconds
    elo_rating = Column(Integer, default=1000)  # ELO rating, default 1000
    is_online = Column(Boolean, default=False)
    is_admin = Column(Boolean, default=False)  # Admin flag (kept for backward compatibility)
    last_seen = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationships
    roles = relationship("Role", secondary=user_roles, back_populates="users")

