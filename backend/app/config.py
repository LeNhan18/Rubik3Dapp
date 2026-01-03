from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database
    # Sử dụng environment variables hoặc default values
    # Trên Fly.io, set các biến này qua: fly secrets set DB_HOST=xxx DB_USER=xxx ...
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_USER: str = "root"
    DB_PASSWORD: str = "nhan1811"
    DB_NAME: str = "rubik_master"
    
    # Hoặc sử dụng DATABASE_URL nếu có (cho Fly.io Postgres hoặc external DB)
    DATABASE_URL: Optional[str] = None
    
    # JWT
    SECRET_KEY: str = "LeThanhNhan_SecretKey_KhongBaoGioDeDoanHiHiHiHi"
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

