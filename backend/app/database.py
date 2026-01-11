from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings
import os
import urllib.parse

# Database connection
# Ưu tiên sử dụng DATABASE_URL nếu có (cho Fly.io hoặc external DB)
# Nếu không có, sử dụng các biến DB_HOST, DB_USER, etc.
if settings.DATABASE_URL:
    DATABASE_URL = settings.DATABASE_URL
elif os.getenv("DATABASE_URL"):
    DATABASE_URL = os.getenv("DATABASE_URL")
else:
    # SQL Server connection với Windows Authentication
    driver = urllib.parse.quote_plus(settings.DB_DRIVER)
    DATABASE_URL = f"mssql+pyodbc://{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}?driver={driver}&trusted_connection=yes"

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=10,
    max_overflow=20,
    echo=False  # Set to True for SQL debugging
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Dependency for getting database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()