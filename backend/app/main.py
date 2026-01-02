from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import auth, users, matches, chat, friends, admin
from app.services.websocket_service import ConnectionManager
from app.utils.dependencies import get_current_user
from app.utils.security import decode_access_token
from app.database import engine, Base, get_db
from app.models.user import User
from sqlalchemy.orm import Session
import uvicorn

# Create database tables (with error handling)
try:
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully")
except Exception as e:
    print(f"Warning: Could not create database tables: {e}")
    print("This is OK if tables already exist or database is not yet available")

app = FastAPI(
    title="Rubik Master API",
    description="API for Rubik's Cube multiplayer and chat",
    version="1.0.0"
)

# CORS Middleware
# Note: Cannot use allow_origins=["*"] with allow_credentials=True
# Use specific origins or set allow_credentials=False
cors_origins = settings.CORS_ORIGINS
if cors_origins == ["*"]:
    # If wildcard, disable credentials for compatibility
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# WebSocket manager
manager = ConnectionManager()

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(matches.router, prefix="/api/matches", tags=["Matches"])
app.include_router(chat.router, prefix="/api/chat", tags=["Chat"])
app.include_router(friends.router, prefix="/api/friends", tags=["Friends"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])

# Set manager in chat router
chat.set_manager(manager)

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: int,
    token: str = None
):
    """WebSocket endpoint for real-time communication"""
    # Verify token if provided
    if token:
        payload = decode_access_token(token)
        if not payload or payload.get("sub") != user_id:
            await websocket.close(code=1008, reason="Invalid token")
            return

    # Get username from database
    username = None
    try:
        db = next(get_db())
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                username = user.username
        except Exception as e:
            print(f"Error getting username for user {user_id}: {e}")
        finally:
            db.close()
    except Exception as e:
        print(f"Error connecting to database: {e}")
        # Continue without username if database is unavailable

    await manager.connect(websocket, user_id, username)

    try:
        while True:
            data = await websocket.receive_json()
            await manager.handle_message(user_id, data)
    except WebSocketDisconnect:
        manager.disconnect(user_id)
    except Exception as e:
        print(f"WebSocket error for user {user_id}: {e}")
        manager.disconnect(user_id)

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Rubik Master API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
