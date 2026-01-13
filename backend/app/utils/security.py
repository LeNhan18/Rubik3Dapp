from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from jose.exceptions import ExpiredSignatureError, JWTClaimsError
import hashlib
import secrets
from app.config import settings
import logging

logger = logging.getLogger(__name__)

def hash_password_simple(password: str, salt: str = None) -> str:
    """Simple password hashing with SHA-256 and salt"""
    if salt is None:
        salt = secrets.token_hex(16)
    
    # Combine password and salt
    password_salt = f"{password}{salt}"
    hash_obj = hashlib.sha256(password_salt.encode('utf-8'))
    
    # Return salt + hash for verification later
    return f"{salt}${hash_obj.hexdigest()}"

def verify_password_simple(plain_password: str, hashed_password: str) -> bool:
    """Verify password with simple hash"""
    if not hashed_password or not plain_password:
        return False
    
    try:
        # Split salt and hash
        if '$' not in hashed_password:
            # Legacy plain text comparison (remove in production!)
            logger.warning("⚠ Plain text password detected!")
            return hashed_password == plain_password
            
        salt, stored_hash = hashed_password.split('$', 1)
        
        # Hash the input password with the stored salt
        password_salt = f"{plain_password}{salt}"
        hash_obj = hashlib.sha256(password_salt.encode('utf-8'))
        calculated_hash = hash_obj.hexdigest()
        
        return calculated_hash == stored_hash
    except Exception as e:
        logger.warning(f"Password verification error: {e}")
        return False


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash"""
    return verify_password_simple(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password"""
    return hash_password_simple(password)


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