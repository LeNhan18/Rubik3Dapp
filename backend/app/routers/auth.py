from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user import UserCreate, UserLogin, UserResponse, TokenResponse
from app.services.auth_service import AuthService
from app.utils.dependencies import get_current_user

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """Register a new user"""
    service = AuthService(db)
    user = service.register(user_data)
    return user

@router.post("/login", response_model=TokenResponse)
async def login(
    login_data: UserLogin,
    db: Session = Depends(get_db)
):
    """Login user and get access token"""
    service = AuthService(db)
    result = service.login(login_data)
    return result


@router.post("/logout")
async def logout(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Logout user (set offline status)"""
    from app.models.user import User
    
    user = db.query(User).filter(User.id == current_user["id"]).first()
    if user:
        user.is_online = False
        db.commit()
    
    return {"message": "Logged out successfully"}


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Refresh access token (get new token with extended expiry)"""
    from app.models.user import User
    from app.utils.security import create_access_token
    
    user = db.query(User).filter(User.id == current_user["id"]).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Create new access token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

