from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.utils.dependencies import get_admin_user
from app.utils.rbac_dependencies import require_permission, require_any_permission
from app.utils.permissions import Permissions
from app.services.admin_service import AdminService
from app.services.role_service import RoleService
from app.schemas.user import UserResponse
from app.models.match import Match
from app.models.chat_message import ChatMessage
from app.models.role import Role, Permission
from pydantic import BaseModel

router = APIRouter()

# Response models
class StatisticsResponse(BaseModel):
    users: dict
    matches: dict
    messages: dict
    friendships: dict

from datetime import datetime

class MatchResponse(BaseModel):
    id: int
    match_id: str
    player1_id: int
    player2_id: int
    scramble: str
    status: str
    player1_time: Optional[int] = None
    player2_time: Optional[int] = None
    winner_id: Optional[int] = None
    is_draw: bool = False
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class MessageResponse(BaseModel):
    id: int
    match_id: str
    sender_id: int
    content: str
    message_type: str
    created_at: datetime

    class Config:
        from_attributes = True

# ========== STATISTICS ==========
@router.get("/statistics", response_model=StatisticsResponse)
async def get_statistics(
    current_user: dict = Depends(require_permission(Permissions.STATISTICS_VIEW)),
    db: Session = Depends(get_db)
):
    """Get system statistics"""
    service = AdminService(db)
    return service.get_statistics()

# ========== USER MANAGEMENT ==========
@router.get("/users", response_model=List[UserResponse])
async def get_all_users(
    limit: int = 100,
    offset: int = 0,
    current_user: dict = Depends(require_permission(Permissions.USERS_VIEW)),
    db: Session = Depends(get_db)
):
    """Get all users"""
    service = AdminService(db)
    return service.get_all_users(limit=limit, offset=offset)

@router.get("/users/count")
async def get_user_count(
    admin_user: dict = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get total user count"""
    service = AdminService(db)
    return {"count": service.get_user_count()}

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: dict = Depends(require_permission(Permissions.USERS_DELETE)),
    db: Session = Depends(get_db)
):
    """Delete a user"""
    service = AdminService(db)
    service.delete_user(user_id)
    return {"message": "User deleted successfully"}

@router.post("/users/{user_id}/toggle-admin", response_model=UserResponse)
async def toggle_admin(
    user_id: int,
    current_user: dict = Depends(require_permission(Permissions.USERS_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Toggle admin status for a user"""
    service = AdminService(db)
    user = service.toggle_admin(user_id)
    return user

@router.post("/users/{user_id}/ban", response_model=UserResponse)
async def ban_user(
    user_id: int,
    current_user: dict = Depends(require_permission(Permissions.USERS_BAN)),
    db: Session = Depends(get_db)
):
    """Ban a user"""
    service = AdminService(db)
    user = service.ban_user(user_id)
    return user

# ========== MATCH MANAGEMENT ==========
@router.get("/matches")
async def get_all_matches(
    limit: int = 100,
    offset: int = 0,
    status_filter: Optional[str] = None,
    current_user: dict = Depends(require_permission(Permissions.MATCHES_VIEW)),
    db: Session = Depends(get_db)
):
    """Get all matches"""
    service = AdminService(db)
    matches = service.get_all_matches(limit=limit, offset=offset, status_filter=status_filter)
    return matches

@router.get("/matches/count")
async def get_match_count(
    status_filter: Optional[str] = None,
    current_user: dict = Depends(require_permission(Permissions.MATCHES_VIEW)),
    db: Session = Depends(get_db)
):
    """Get total match count"""
    service = AdminService(db)
    return {"count": service.get_match_count(status_filter=status_filter)}

@router.delete("/matches/{match_id}")
async def delete_match(
    match_id: str,
    current_user: dict = Depends(require_permission(Permissions.MATCHES_DELETE)),
    db: Session = Depends(get_db)
):
    """Delete a match"""
    service = AdminService(db)
    service.delete_match(match_id)
    return {"message": "Match deleted successfully"}

# ========== MESSAGE MANAGEMENT ==========
@router.get("/messages")
async def get_all_messages(
    limit: int = 100,
    offset: int = 0,
    match_id: Optional[str] = None,
    current_user: dict = Depends(require_permission(Permissions.MESSAGES_VIEW)),
    db: Session = Depends(get_db)
):
    """Get all messages"""
    service = AdminService(db)
    messages = service.get_all_messages(limit=limit, offset=offset, match_id=match_id)
    return messages

@router.get("/messages/count")
async def get_message_count(
    match_id: Optional[str] = None,
    current_user: dict = Depends(require_permission(Permissions.MESSAGES_VIEW)),
    db: Session = Depends(get_db)
):
    """Get total message count"""
    service = AdminService(db)
    return {"count": service.get_message_count(match_id=match_id)}

@router.delete("/messages/{message_id}")
async def delete_message(
    message_id: int,
    current_user: dict = Depends(require_permission(Permissions.MESSAGES_DELETE)),
    db: Session = Depends(get_db)
):
    """Delete a message"""
    service = AdminService(db)
    service.delete_message(message_id)
    return {"message": "Message deleted successfully"}

# ========== ROLE MANAGEMENT ==========
class RoleCreate(BaseModel):
    name: str
    description: Optional[str] = None

class RoleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None

class PermissionCreate(BaseModel):
    name: str
    resource: str
    action: str
    description: Optional[str] = None

class RoleResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class PermissionResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    resource: str
    action: str
    created_at: datetime

    class Config:
        from_attributes = True

@router.get("/roles", response_model=List[RoleResponse])
async def get_all_roles(
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Get all roles"""
    service = RoleService(db)
    return service.get_all_roles()

@router.post("/roles", response_model=RoleResponse)
async def create_role(
    role_data: RoleCreate,
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Create a new role"""
    service = RoleService(db)
    return service.create_role(role_data.name, role_data.description)

@router.put("/roles/{role_id}", response_model=RoleResponse)
async def update_role(
    role_id: int,
    role_data: RoleUpdate,
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Update a role"""
    service = RoleService(db)
    return service.update_role(role_id, role_data.name, role_data.description)

@router.delete("/roles/{role_id}")
async def delete_role(
    role_id: int,
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Delete a role"""
    service = RoleService(db)
    service.delete_role(role_id)
    return {"message": "Role deleted successfully"}

@router.get("/permissions", response_model=List[PermissionResponse])
async def get_all_permissions(
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_PERMISSIONS)),
    db: Session = Depends(get_db)
):
    """Get all permissions"""
    service = RoleService(db)
    return service.get_all_permissions()

@router.post("/permissions", response_model=PermissionResponse)
async def create_permission(
    permission_data: PermissionCreate,
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_PERMISSIONS)),
    db: Session = Depends(get_db)
):
    """Create a new permission"""
    service = RoleService(db)
    return service.create_permission(
        permission_data.name,
        permission_data.resource,
        permission_data.action,
        permission_data.description
    )

@router.get("/roles/{role_id}/permissions", response_model=List[PermissionResponse])
async def get_role_permissions(
    role_id: int,
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Get all permissions for a role"""
    service = RoleService(db)
    return service.get_role_permissions(role_id)

@router.post("/roles/{role_id}/permissions/{permission_id}", response_model=RoleResponse)
async def assign_permission_to_role(
    role_id: int,
    permission_id: int,
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Assign a permission to a role"""
    service = RoleService(db)
    return service.assign_permission_to_role(role_id, permission_id)

@router.delete("/roles/{role_id}/permissions/{permission_id}", response_model=RoleResponse)
async def remove_permission_from_role(
    role_id: int,
    permission_id: int,
    current_user: dict = Depends(require_permission(Permissions.SYSTEM_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Remove a permission from a role"""
    service = RoleService(db)
    return service.remove_permission_from_role(role_id, permission_id)

@router.get("/users/{user_id}/roles", response_model=List[RoleResponse])
async def get_user_roles(
    user_id: int,
    current_user: dict = Depends(require_permission(Permissions.USERS_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Get all roles for a user"""
    service = RoleService(db)
    return service.get_user_roles(user_id)

@router.post("/users/{user_id}/roles/{role_id}", response_model=UserResponse)
async def assign_role_to_user(
    user_id: int,
    role_id: int,
    current_user: dict = Depends(require_permission(Permissions.USERS_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Assign a role to a user"""
    service = RoleService(db)
    return service.assign_role_to_user(user_id, role_id)

@router.delete("/users/{user_id}/roles/{role_id}", response_model=UserResponse)
async def remove_role_from_user(
    user_id: int,
    role_id: int,
    current_user: dict = Depends(require_permission(Permissions.USERS_MANAGE_ROLES)),
    db: Session = Depends(get_db)
):
    """Remove a role from a user"""
    service = RoleService(db)
    return service.remove_role_from_user(user_id, role_id)

