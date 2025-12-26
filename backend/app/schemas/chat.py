from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.chat_message import MessageType

class ChatMessageCreate(BaseModel):
    match_id: str
    content: str
    message_type: str = "text"

class ChatMessageResponse(BaseModel):
    id: int
    match_id: str
    sender_id: int
    sender_username: Optional[str] = None
    content: str
    message_type: str
    created_at: datetime

    class Config:
        from_attributes = True

