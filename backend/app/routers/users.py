from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user import UserResponse
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

