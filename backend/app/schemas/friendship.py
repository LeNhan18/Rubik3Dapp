from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.friendship import FriendshipStatus

class FriendshipCreate(BaseModel):
    user2_id: int

class FriendshipResponse(BaseModel):
    id: int
    user1_id: int
    user2_id: int
    status: str
    created_at: datetime
    user1_username: Optional[str] = None
    user2_username: Optional[str] = None

    class Config:
        from_attributes = True

