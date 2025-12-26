from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.match import MatchStatus

class MatchCreate(BaseModel):
    opponent_id: Optional[int] = None  # None = find random opponent

class MatchResult(BaseModel):
    solve_time: int  # milliseconds

class MatchResponse(BaseModel):
    id: int
    match_id: str
    player1_id: int
    player2_id: int
    scramble: str
    status: str
    player1_time: Optional[int] = None
    player2_time: Optional[int] = None
    winner_id: Optional[int] = None
    is_draw: bool = False
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True

