from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from jose.exceptions import ExpiredSignatureError, JWTClaimsError
from passlib.context import CryptContext
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Use bcrypt for password hashing (more compatible, no extra dependencies)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash"""
    if not hashed_password or not plain_password:
        return False
    
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception as e:
        logger.warning(f"Password verification error: {e}")
        # Nếu hash không hợp lệ, có thể là plain text (cho backward compatibility)
        # CHỈ CHO DEVELOPMENT - XÓA ĐI KHI PRODUCTION!
        if hashed_password == plain_password:
            logger.warning("⚠️ Plain text password detected - should be hashed!")
            return True
        return False


def get_password_hash(password: str) -> str:
    """Hash a password"""
    # Bcrypt has a 72 byte limit, truncate if necessary
    if len(password.encode('utf-8')) > 72:
        password = password[:72]
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> Optional[dict]:
    """Decode and verify a JWT token"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except ExpiredSignatureError:
        logger.warning("Token has expired")
        return None
    except JWTClaimsError as e:
        logger.warning(f"JWT claims error: {e}")
        return None
    except JWTError as e:
        logger.warning(f"JWT decode error: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error decoding token: {e}")
        return None