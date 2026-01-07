from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.friendship import Friendship, FriendshipStatus
from app.models.user import User
from app.schemas.friendship import FriendshipCreate
from typing import List

class FriendshipService:
    def __init__(self, db: Session):
        self.db = db

    def send_friend_request(self, user1_id: int, friendship_data: FriendshipCreate) -> Friendship:
        """Send a friend request"""
        if user1_id == friendship_data.user2_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot add yourself as a friend"
            )
        # Check if user2 exists
        user2 = self.db.query(User).filter(User.id == friendship_data.user2_id).first()
        if not user2:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        # Check if friendship already exists
        existing = self.db.query(Friendship).filter(
            ((Friendship.user1_id == user1_id) & (Friendship.user2_id == friendship_data.user2_id)) |
            ((Friendship.user1_id == friendship_data.user2_id) & (Friendship.user2_id == user1_id))
        ).first()
        
        if existing:
            if existing.status == FriendshipStatus.accepted:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Already friends"
                )
            elif existing.status == FriendshipStatus.pending:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Friend request already pending"
                )
        # Create friendship
        friendship = Friendship(
            user1_id=user1_id,
            user2_id=friendship_data.user2_id,
            status=FriendshipStatus.pending
        )
        
        self.db.add(friendship)
        self.db.commit()
        self.db.refresh(friendship)
        
        return friendship

    def accept_friend_request(self, user_id: int, friendship_id: int) -> Friendship:
        """Accept a friend request"""
        friendship = self.db.query(Friendship).filter(Friendship.id == friendship_id).first()
        
        if not friendship:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Friendship not found"
            )
        
        if friendship.user2_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not the recipient of this request"
            )
        
        if friendship.status != FriendshipStatus.pending:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Friendship is not pending"
            )
        
        friendship.status = FriendshipStatus.accepted
        self.db.commit()
        self.db.refresh(friendship)
        
        return friendship

    def get_friends(self, user_id: int) -> List[User]:
        """Get list of friends for a user"""
        friendships = self.db.query(Friendship).filter(
            ((Friendship.user1_id == user_id) | (Friendship.user2_id == user_id)) &
            (Friendship.status == FriendshipStatus.accepted)
        ).all()
        
        friend_ids = []
        for friendship in friendships:
            if friendship.user1_id == user_id:
                friend_ids.append(friendship.user2_id)
            else:
                friend_ids.append(friendship.user1_id)
        
        friends = self.db.query(User).filter(User.id.in_(friend_ids)).all()
        return friends

    def get_pending_requests(self, user_id: int) -> List[Friendship]:
        """Get pending friend requests for a user"""
        return self.db.query(Friendship).filter(
            (Friendship.user2_id == user_id) &
            (Friendship.status == FriendshipStatus.pending)
        ).all()

