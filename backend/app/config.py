from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database - SQL Server với Windows Authentication
    # Sử dụng environment variables hoặc default values
    DB_HOST: str = "localhost"
    DB_PORT: int = 1433
    DB_NAME: str = "rubik_master"
    DB_DRIVER: str = "ODBC Driver 17 for SQL Server"
    
    # Chỉ dùng khi không dùng Windows Authentication
    DB_USER: Optional[str] = None
    DB_PASSWORD: Optional[str] = None
    
    # Hoặc sử dụng DATABASE_URL nếu có (cho Fly.io hoặc external DB)
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

