from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.utils.security import decode_access_token
import logging

logger = logging.getLogger(__name__)

security = HTTPBearer()


async def get_current_user(
        credentials: HTTPAuthorizationCredentials = Depends(security),
        db: Session = Depends(get_db)
) -> dict:
    """Get current authenticated user"""
    token = credentials.credentials

    # Log token for debugging (remove in production)
    logger.debug(f"Attempting to decode token: {token[:20]}...")

    payload = decode_access_token(token)

    if payload is None:
        logger.warning("Token decode failed - payload is None")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # sub is stored as string in JWT, convert to int
    user_id_str = payload.get("sub")
    logger.debug(f"Decoded user_id from token: {user_id_str}")

    if user_id_str is None:
        logger.warning("Token payload missing 'sub' field")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token format",
        )

    try:
        user_id = int(user_id_str)
    except (ValueError, TypeError):
        logger.warning(f"Invalid user_id format: {user_id_str}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token format",
        )

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        logger.warning(f"User with id {user_id} not found in database")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"User not found (id: {user_id})",
        )

    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
    }