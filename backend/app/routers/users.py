from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user import UserResponse, UserUpdate
from app.utils.dependencies import get_current_user
from app.models.user import User
from typing import List
import os
import uuid
from pathlib import Path

router = APIRouter()

# Tạo thư mục uploads nếu chưa có
UPLOAD_DIR = Path(__file__).parent.parent.parent / "uploads" / "avatars"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

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

@router.post("/me/avatar", response_model=UserResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload avatar image for current user"""
    try:
        # Kiểm tra file có tồn tại không
        if not file:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No file provided"
            )
        
        # Đọc file content trước để kiểm tra magic bytes
        file_content = await file.read()
        
        # Kiểm tra file rỗng
        if len(file_content) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File is empty"
            )
        
        # Kiểm tra magic bytes để xác định file type (quan trọng hơn content_type)
        is_valid_image = False
        if len(file_content) >= 4:
            # PNG: 89 50 4E 47
            if file_content[:4] == b'\x89PNG':
                is_valid_image = True
            # JPEG: FF D8
            elif file_content[:2] == b'\xff\xd8':
                is_valid_image = True
            # GIF: 47 49 46 38 (GIF8)
            elif file_content.length >= 6 and file_content[:6] in [b'GIF87a', b'GIF89a']:
                is_valid_image = True
            # WebP: RIFF...WEBP
            elif file_content.length >= 12 and file_content[:4] == b'RIFF' and file_content[8:12] == b'WEBP':
                is_valid_image = True
        
        # Kiểm tra content_type (nếu có) hoặc magic bytes
        # Cho phép application/octet-stream nếu magic bytes là image
        if file.content_type:
            if file.content_type.startswith('image/'):
                # Content type là image, OK
                pass
            elif file.content_type == 'application/octet-stream':
                # Cho phép octet-stream nếu magic bytes là image
                if not is_valid_image:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="File does not appear to be a valid image (PNG, JPEG, GIF, or WebP)"
                    )
            else:
                # Content type khác và không phải image theo magic bytes
                if not is_valid_image:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"File must be an image. Got: {file.content_type}"
                    )
        elif not is_valid_image:
            # Nếu không có content_type và không phải image theo magic bytes
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File does not appear to be a valid image (PNG, JPEG, GIF, or WebP)"
            )
    
        # Giới hạn kích thước file (5MB)
        if len(file_content) > 5 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File size must be less than 5MB. Got: {len(file_content)} bytes"
            )
        
        # Tạo tên file unique
        file_extension = Path(file.filename).suffix if file.filename else '.jpg'
        if not file_extension or file_extension == '':
            # Xác định extension từ content_type hoặc magic bytes
            if file.content_type:
                if 'png' in file.content_type:
                    file_extension = '.png'
                elif 'jpeg' in file.content_type or 'jpg' in file.content_type:
                    file_extension = '.jpg'
                elif 'gif' in file.content_type:
                    file_extension = '.gif'
                else:
                    file_extension = '.jpg'
            else:
                # Dựa vào magic bytes
                if file_content[:4] == b'\x89PNG':
                    file_extension = '.png'
                elif file_content[:2] == b'\xff\xd8':
                    file_extension = '.jpg'
                elif file_content[:6] in [b'GIF87a', b'GIF89a']:
                    file_extension = '.gif'
                else:
                    file_extension = '.jpg'
        
        file_name = f"{current_user['id']}_{uuid.uuid4()}{file_extension}"
        file_path = UPLOAD_DIR / file_name
        
        # Đảm bảo thư mục tồn tại
        UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
        
        # Lưu file
        try:
            with open(file_path, "wb") as f:
                f.write(file_content)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to save file: {str(e)}"
            )
        
        # Tạo URL (relative path)
        avatar_url = f"api/users/avatars/{file_name}"
        
        # Cập nhật avatar_url trong database
        user = db.query(User).filter(User.id == current_user["id"]).first()
        if not user:
            # Xóa file nếu user không tồn tại
            try:
                if file_path.exists():
                    os.remove(file_path)
            except:
                pass
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Xóa avatar cũ nếu có
        if user.avatar_url:
            # Extract filename from URL (handle both formats)
            old_file_name = user.avatar_url.split("/")[-1]
            old_file = UPLOAD_DIR / old_file_name
            if old_file.exists():
                try:
                    os.remove(old_file)
                except:
                    pass  # Ignore errors when deleting old file
        
        user.avatar_url = avatar_url
        db.commit()
        db.refresh(user)
        
        return user
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading avatar: {str(e)}"
        )

@router.get("/avatars/{file_name}")
async def get_avatar(file_name: str):
    """Serve avatar images"""
    file_path = UPLOAD_DIR / file_name
    if not file_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Avatar not found"
        )
    return FileResponse(file_path)

