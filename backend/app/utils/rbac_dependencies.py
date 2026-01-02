from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.utils.dependencies import get_current_user
from app.utils.permissions import PermissionChecker, Permissions

def require_permission(permission: str):
    """Dependency factory to require a specific permission"""
    async def permission_checker(
        current_user: dict = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> dict:
        user_id = current_user["id"]
        
        # Check if user has the permission
        if not PermissionChecker.has_permission(db, user_id, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission required: {permission}"
            )
        
        return current_user
    
    return permission_checker

def require_any_permission(permissions: List[str]):
    """Dependency factory to require any of the specified permissions"""
    async def permission_checker(
        current_user: dict = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> dict:
        user_id = current_user["id"]
        
        # Check if user has any of the permissions
        if not PermissionChecker.has_any_permission(db, user_id, permissions):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"One of these permissions required: {', '.join(permissions)}"
            )
        
        return current_user
    
    return permission_checker

def require_all_permissions(permissions: List[str]):
    """Dependency factory to require all of the specified permissions"""
    async def permission_checker(
        current_user: dict = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> dict:
        user_id = current_user["id"]
        
        # Check if user has all permissions
        if not PermissionChecker.has_all_permissions(db, user_id, permissions):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"All of these permissions required: {', '.join(permissions)}"
            )
        
        return current_user
    
    return permission_checker

def require_role(role_name: str):
    """Dependency factory to require a specific role"""
    async def role_checker(
        current_user: dict = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> dict:
        user_id = current_user["id"]
        
        # Check if user has the role
        if not PermissionChecker.has_role(db, user_id, role_name):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role required: {role_name}"
            )
        
        return current_user
    
    return role_checker

# Convenience dependencies for common permission checks
require_admin = require_role("admin")
require_moderator = require_any_permission([Permissions.MATCHES_DELETE, Permissions.MESSAGES_DELETE])

