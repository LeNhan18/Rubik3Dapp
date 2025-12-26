from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user import UserResponse, UserUpdate
from app.utils.dependencies import get_current_user
from app.models.user import User
from typing import List

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user information"""
    user = db.query(User).filter(User.id == current_user["id"]).first()
    return user

@router.get("/online", response_model=List[UserResponse])
async def get_online_users(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get list of online users"""
    users = db.query(User).filter(
        User.is_online == True,
        User.id != current_user["id"]
    ).all()
    return users

@router.get("/search/{username}", response_model=List[UserResponse])
async def search_users(
    username: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Search users by username"""
    users = db.query(User).filter(
        User.username.like(f"%{username}%"),
        User.id != current_user["id"]
    ).limit(20).all()
    return users

@router.get("/leaderboard", response_model=List[UserResponse])
async def get_leaderboard(
    db: Session = Depends(get_db),
    limit: int = 100
):
    """Get ELO leaderboard"""
    users = db.query(User).order_by(
        User.elo_rating.desc()
    ).limit(limit).all()
    return users

@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user profile"""
    user = db.query(User).filter(User.id == current_user["id"]).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check if username is already taken (if updating username)
    if user_update.username and user_update.username != user.username:
        existing_user = db.query(User).filter(
            User.username == user_update.username
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
        user.username = user_update.username
    
    # Check if email is already taken (if updating email)
    if user_update.email and user_update.email != user.email:
        existing_user = db.query(User).filter(
            User.email == user_update.email
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already taken"
            )
        user.email = user_update.email
    
    # Update avatar_url if provided
    if user_update.avatar_url is not None:
        user.avatar_url = user_update.avatar_url
    
    db.commit()
    db.refresh(user)
    
    return user

