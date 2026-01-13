from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.chat import ChatMessageCreate, ChatMessageResponse
from app.services.chat_service import ChatService
from app.utils.dependencies import get_current_user
from typing import List

router = APIRouter()

# Import manager from main (will be set after app initialization)
_manager = None

def set_manager(manager):
    """Set the WebSocket manager instance"""
    global _manager
    _manager = manager

@router.post("/send", response_model=ChatMessageResponse)
async def send_message(
    message_data: ChatMessageCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a chat message in a match"""
    service = ChatService(db)
    message = service.send_message(current_user["id"], message_data)
    
    # Broadcast message via WebSocket if manager is available
    if _manager:
        await _manager.broadcast_to_match({
            "type": "chat",
            "match_id": message.match_id,  # IMPORTANT: Client needs this to filter messages
            "sender_id": message.sender_id,
            "sender_username": message.sender.username,
            "content": message.content,
            "timestamp": message.created_at.isoformat()
        }, message.match_id, exclude_user_id=message.sender_id)  # Exclude sender since they already have optimistic update
    
    # Return with sender username
    return {
        "id": message.id,
        "match_id": message.match_id,
        "sender_id": message.sender_id,
        "sender_username": message.sender.username,
        "content": message.content,
        "message_type": message.message_type.value,
        "created_at": message.created_at
    }

@router.get("/{match_id}/messages", response_model=List[ChatMessageResponse])
async def get_messages(
    match_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 50,
    offset: int = 0
):
    """Get chat messages for a match"""
    service = ChatService(db)
    messages = service.get_messages(match_id, limit, offset)
    
    return [
        {
            "id": msg.id,
            "match_id": msg.match_id,
            "sender_id": msg.sender_id,
            "sender_username": msg.sender.username,
            "content": msg.content,
            "message_type": msg.message_type.value,
            "created_at": msg.created_at
        }
        for msg in messages
    ]


@router.delete("/messages/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    message_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a chat message (only own messages)"""
    from app.models.chat_message import ChatMessage
    from fastapi import HTTPException, status
    
    message = db.query(ChatMessage).filter(ChatMessage.id == message_id).first()
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Check if user is the sender
    if message.sender_id != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own messages"
        )
    
    db.delete(message)
    db.commit()
    return None

