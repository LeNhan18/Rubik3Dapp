from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.role import Role, Permission
from app.models.user import User
from typing import List, Optional

class RoleService:
    def __init__(self, db: Session):
        self.db = db

    # ========== ROLE MANAGEMENT ==========
    def get_all_roles(self) -> List[Role]:
        """Get all roles"""
        return self.db.query(Role).all()

    def get_role_by_id(self, role_id: int) -> Optional[Role]:
        """Get role by ID"""
        return self.db.query(Role).filter(Role.id == role_id).first()

    def get_role_by_name(self, role_name: str) -> Optional[Role]:
        """Get role by name"""
        return self.db.query(Role).filter(Role.name == role_name).first()

    def create_role(self, name: str, description: Optional[str] = None) -> Role:
        """Create a new role"""
        existing = self.db.query(Role).filter(Role.name == name).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Role already exists"
            )
        
        role = Role(name=name, description=description)
        self.db.add(role)
        self.db.commit()
        self.db.refresh(role)
        return role

    def update_role(self, role_id: int, name: Optional[str] = None, description: Optional[str] = None) -> Role:
        """Update a role"""
        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )
        
        if name and name != role.name:
            existing = self.db.query(Role).filter(Role.name == name).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Role name already exists"
                )
            role.name = name
        
        if description is not None:
            role.description = description
        
        self.db.commit()
        self.db.refresh(role)
        return role

    def delete_role(self, role_id: int) -> bool:
        """Delete a role (cannot delete default roles)"""
        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )
        
        # Prevent deletion of default roles
        if role.name in ['admin', 'moderator', 'user']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete default role"
            )
        
        self.db.delete(role)
        self.db.commit()
        return True

    # ========== PERMISSION MANAGEMENT ==========
    def get_all_permissions(self) -> List[Permission]:
        """Get all permissions"""
        return self.db.query(Permission).all()

    def get_permission_by_id(self, permission_id: int) -> Optional[Permission]:
        """Get permission by ID"""
        return self.db.query(Permission).filter(Permission.id == permission_id).first()

    def get_permission_by_name(self, permission_name: str) -> Optional[Permission]:
        """Get permission by name"""
        return self.db.query(Permission).filter(Permission.name == permission_name).first()

    def create_permission(self, name: str, resource: str, action: str, description: Optional[str] = None) -> Permission:
        """Create a new permission"""
        existing = self.db.query(Permission).filter(Permission.name == name).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Permission already exists"
            )
        
        permission = Permission(
            name=name,
            resource=resource,
            action=action,
            description=description
        )
        self.db.add(permission)
        self.db.commit()
        self.db.refresh(permission)
        return permission

    # ========== ROLE-PERMISSION MANAGEMENT ==========
    def assign_permission_to_role(self, role_id: int, permission_id: int) -> Role:
        """Assign a permission to a role"""
        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )
        
        permission = self.db.query(Permission).filter(Permission.id == permission_id).first()
        if not permission:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not found"
            )
        
        if permission not in role.permissions:
            role.permissions.append(permission)
            self.db.commit()
            self.db.refresh(role)
        
        return role

    def remove_permission_from_role(self, role_id: int, permission_id: int) -> Role:
        """Remove a permission from a role"""
        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )
        
        permission = self.db.query(Permission).filter(Permission.id == permission_id).first()
        if not permission:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not found"
            )
        
        if permission in role.permissions:
            role.permissions.remove(permission)
            self.db.commit()
            self.db.refresh(role)
        
        return role

    def get_role_permissions(self, role_id: int) -> List[Permission]:
        """Get all permissions for a role"""
        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )
        
        return role.permissions

    # ========== USER-ROLE MANAGEMENT ==========
    def assign_role_to_user(self, user_id: int, role_id: int) -> User:
        """Assign a role to a user"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )
        
        if role not in user.roles:
            user.roles.append(role)
            self.db.commit()
            self.db.refresh(user)
        
        return user

    def remove_role_from_user(self, user_id: int, role_id: int) -> User:
        """Remove a role from a user"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role not found"
            )
        
        # Prevent removing the last role from a user
        if len(user.roles) <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User must have at least one role"
            )
        
        if role in user.roles:
            user.roles.remove(role)
            self.db.commit()
            self.db.refresh(user)
        
        return user

    def get_user_roles(self, user_id: int) -> List[Role]:
        """Get all roles for a user"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return user.roles

