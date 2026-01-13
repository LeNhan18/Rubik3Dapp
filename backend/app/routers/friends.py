from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.friendship import FriendshipCreate, FriendshipResponse
from app.services.friendship_service import FriendshipService
from app.utils.dependencies import get_current_user
from app.models.user import User
from typing import List

router = APIRouter()

@router.post("/request", response_model=FriendshipResponse)
async def send_friend_request(
    friendship_data: FriendshipCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a friend request"""
    service = FriendshipService(db)
    friendship = service.send_friend_request(current_user["id"], friendship_data)
    
    # Get usernames
    user1 = db.query(User).filter(User.id == friendship.user1_id).first()
    user2 = db.query(User).filter(User.id == friendship.user2_id).first()
    
    return {
        "id": friendship.id,
        "user1_id": friendship.user1_id,
        "user2_id": friendship.user2_id,
        "status": friendship.status.value,
        "created_at": friendship.created_at,
        "user1_username": user1.username,
        "user2_username": user2.username
    }

@router.post("/{friendship_id}/accept", response_model=FriendshipResponse)
async def accept_friend_request(
    friendship_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Accept a friend request"""
    service = FriendshipService(db)
    friendship = service.accept_friend_request(current_user["id"], friendship_id)
    
    # Get usernames
    user1 = db.query(User).filter(User.id == friendship.user1_id).first()
    user2 = db.query(User).filter(User.id == friendship.user2_id).first()
    
    return {
        "id": friendship.id,
        "user1_id": friendship.user1_id,
        "user2_id": friendship.user2_id,
        "status": friendship.status.value,
        "created_at": friendship.created_at,
        "user1_username": user1.username,
        "user2_username": user2.username
    }

@router.get("/", response_model=List[dict])
async def get_friends(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get list of friends"""
    service = FriendshipService(db)
    friends = service.get_friends(current_user["id"])
    
    return [
        {
            "id": friend.id,
            "username": friend.username,
            "email": friend.email,
            "avatar_url": friend.avatar_url,
            "is_online": friend.is_online,
            "total_wins": friend.total_wins,
            "total_losses": friend.total_losses,
            "total_draws": friend.total_draws,
            "average_time": float(friend.average_time) if friend.average_time else None,
            "best_time": friend.best_time,
            "elo_rating": friend.elo_rating,
            "last_seen": friend.last_seen.isoformat() if friend.last_seen else None,
            "created_at": friend.created_at.isoformat() if friend.created_at else None
        }
        for friend in friends
    ]

@router.get("/pending", response_model=List[FriendshipResponse])
async def get_pending_requests(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get pending friend requests"""
    service = FriendshipService(db)
    requests = service.get_pending_requests(current_user["id"])
    
    result = []
    for req in requests:
        user1 = db.query(User).filter(User.id == req.user1_id).first()
        user2 = db.query(User).filter(User.id == req.user2_id).first()
        result.append({
            "id": req.id,
            "user1_id": req.user1_id,
            "user2_id": req.user2_id,
            "status": req.status.value,
            "created_at": req.created_at,
            "user1_username": user1.username,
            "user2_username": user2.username
        })
    
    return result


@router.post("/{friendship_id}/reject", response_model=FriendshipResponse)
async def reject_friend_request(
    friendship_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reject a friend request"""
    from app.models.friendship import Friendship, FriendshipStatus
    
    friendship = db.query(Friendship).filter(Friendship.id == friendship_id).first()
    if not friendship:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Friend request not found"
        )
    
    # Check if user is the recipient
    if friendship.user2_id != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only reject requests sent to you"
        )
    
    # Check if request is pending
    if friendship.status != FriendshipStatus.pending:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Friend request is not pending"
        )
    
    # Delete the friendship (reject = delete)
    db.delete(friendship)
    db.commit()
    
    # Get usernames for response
    user1 = db.query(User).filter(User.id == friendship.user1_id).first()
    user2 = db.query(User).filter(User.id == friendship.user2_id).first()
    
    return {
        "id": friendship_id,
        "user1_id": friendship.user1_id,
        "user2_id": friendship.user2_id,
        "status": "rejected",
        "created_at": friendship.created_at,
        "user1_username": user1.username,
        "user2_username": user2.username
    }


@router.delete("/{friendship_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unfriend(
    friendship_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Unfriend (delete friendship)"""
    from app.models.friendship import Friendship, FriendshipStatus
    
    friendship = db.query(Friendship).filter(Friendship.id == friendship_id).first()
    if not friendship:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Friendship not found"
        )
    
    # Check if user is part of this friendship
    if current_user["id"] not in [friendship.user1_id, friendship.user2_id]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete this friendship"
        )
    
    # Check if they are actually friends
    if friendship.status != FriendshipStatus.accepted:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Friendship is not accepted"
        )
    
    db.delete(friendship)
    db.commit()
    return None

