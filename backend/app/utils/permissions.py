from typing import List, Set
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.role import Role, Permission

class PermissionChecker:
    """Utility class for checking user permissions"""
    
    @staticmethod
    def get_user_permissions(db: Session, user_id: int) -> Set[str]:
        """Get all permission names for a user"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return set()
        
        permissions = set()
        for role in user.roles:
            for permission in role.permissions:
                permissions.add(permission.name)
        
        return permissions
    
    @staticmethod
    def has_permission(db: Session, user_id: int, permission_name: str) -> bool:
        """Check if user has a specific permission"""
        permissions = PermissionChecker.get_user_permissions(db, user_id)
        return permission_name in permissions
    
    @staticmethod
    def has_any_permission(db: Session, user_id: int, permission_names: List[str]) -> bool:
        """Check if user has any of the specified permissions"""
        permissions = PermissionChecker.get_user_permissions(db, user_id)
        return any(perm in permissions for perm in permission_names)
    
    @staticmethod
    def has_all_permissions(db: Session, user_id: int, permission_names: List[str]) -> bool:
        """Check if user has all of the specified permissions"""
        permissions = PermissionChecker.get_user_permissions(db, user_id)
        return all(perm in permissions for perm in permission_names)
    
    @staticmethod
    def has_role(db: Session, user_id: int, role_name: str) -> bool:
        """Check if user has a specific role"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return False
        
        return any(role.name == role_name for role in user.roles)
    
    @staticmethod
    def get_user_roles(db: Session, user_id: int) -> List[str]:
        """Get all role names for a user"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return []
        
        return [role.name for role in user.roles]

# Permission constants
class Permissions:
    # User permissions
    USERS_VIEW = "users.view"
    USERS_CREATE = "users.create"
    USERS_UPDATE = "users.update"
    USERS_DELETE = "users.delete"
    USERS_MANAGE_ROLES = "users.manage_roles"
    USERS_BAN = "users.ban"
    
    # Match permissions
    MATCHES_VIEW = "matches.view"
    MATCHES_CREATE = "matches.create"
    MATCHES_UPDATE = "matches.update"
    MATCHES_DELETE = "matches.delete"
    
    # Message permissions
    MESSAGES_VIEW = "messages.view"
    MESSAGES_DELETE = "messages.delete"
    
    # Statistics permissions
    STATISTICS_VIEW = "statistics.view"
    
    # System permissions
    SYSTEM_MANAGE_ROLES = "system.manage_roles"
    SYSTEM_MANAGE_PERMISSIONS = "system.manage_permissions"

