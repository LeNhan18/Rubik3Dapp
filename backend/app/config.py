from pydantic_settings import BaseSettings
from typing import Optional
import os

class Settings(BaseSettings):
    # Database - MySQL
    # Sử dụng environment variables hoặc default values
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_USER: str = "root"
    DB_PASSWORD: str = ""
    DB_NAME: str = "rubik_master"
    
    # Hoặc sử dụng DATABASE_URL nếu có (cho Fly.io hoặc external DB)
    DATABASE_URL: Optional[str] = None
    
    # JWT - MUST be set via environment variable for production
    # Generate new key: python -c "import secrets; print(secrets.token_urlsafe(64))"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # CORS
    CORS_ORIGINS: list = ["*"]
    
    # WebSocket
    WS_HEARTBEAT_INTERVAL: int = 30
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()

# Validate SECRET_KEY on startup
if not settings.SECRET_KEY:
    raise ValueError(
        "SECRET_KEY is not set! Please set it in .env file.\n"
        "Generate one using: python -c \"import secrets; print(secrets.token_urlsafe(64))\""
    )

