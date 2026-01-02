"""
Script khởi tạo RBAC (Roles và Permissions) và gán roles cho users cũ
Chạy script này: python init_rbac.py
"""

import sys
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app.models.role import Role, Permission
from app.models.user import User
from app.utils.permissions import Permissions

# Đảm bảo tất cả tables đã được tạo
Base.metadata.create_all(bind=engine)

# Định nghĩa roles
ROLES = [
    {"name": "admin", "description": "Full system access"},
    {"name": "moderator", "description": "Moderate content and users"},
    {"name": "user", "description": "Standard user access"},
]

# Định nghĩa permissions
PERMISSIONS = [
    # User permissions
    {"name": Permissions.USERS_VIEW, "description": "View users", "resource": "users", "action": "view"},
    {"name": Permissions.USERS_CREATE, "description": "Create users", "resource": "users", "action": "create"},
    {"name": Permissions.USERS_UPDATE, "description": "Update users", "resource": "users", "action": "update"},
    {"name": Permissions.USERS_DELETE, "description": "Delete users", "resource": "users", "action": "delete"},
    {"name": Permissions.USERS_MANAGE_ROLES, "description": "Manage user roles", "resource": "users", "action": "manage_roles"},
    {"name": Permissions.USERS_BAN, "description": "Ban users", "resource": "users", "action": "ban"},
    
    # Match permissions
    {"name": Permissions.MATCHES_VIEW, "description": "View matches", "resource": "matches", "action": "view"},
    {"name": Permissions.MATCHES_CREATE, "description": "Create matches", "resource": "matches", "action": "create"},
    {"name": Permissions.MATCHES_UPDATE, "description": "Update matches", "resource": "matches", "action": "update"},
    {"name": Permissions.MATCHES_DELETE, "description": "Delete matches", "resource": "matches", "action": "delete"},
    
    # Message permissions
    {"name": Permissions.MESSAGES_VIEW, "description": "View messages", "resource": "messages", "action": "view"},
    {"name": Permissions.MESSAGES_DELETE, "description": "Delete messages", "resource": "messages", "action": "delete"},
    
    # Statistics permissions
    {"name": Permissions.STATISTICS_VIEW, "description": "View statistics", "resource": "statistics", "action": "view"},
    
    # System permissions
    {"name": Permissions.SYSTEM_MANAGE_ROLES, "description": "Manage roles and permissions", "resource": "system", "action": "manage_roles"},
    {"name": Permissions.SYSTEM_MANAGE_PERMISSIONS, "description": "Manage permissions", "resource": "system", "action": "manage_permissions"},
]

# Mapping roles với permissions
ROLE_PERMISSIONS = {
    "admin": [p["name"] for p in PERMISSIONS],  # Admin có tất cả permissions
    "moderator": [
        Permissions.USERS_VIEW,
        Permissions.USERS_BAN,
        Permissions.MATCHES_VIEW,
        Permissions.MATCHES_DELETE,
        Permissions.MESSAGES_VIEW,
        Permissions.MESSAGES_DELETE,
        Permissions.STATISTICS_VIEW,
    ],
    "user": [
        Permissions.USERS_VIEW,
        Permissions.MATCHES_VIEW,
        Permissions.MATCHES_CREATE,
        Permissions.MESSAGES_VIEW,
    ],
}


def create_roles(db: Session):
    """Tạo roles nếu chưa tồn tại"""
    print("\n=== Tạo Roles ===")
    created_roles = {}
    
    for role_data in ROLES:
        role = db.query(Role).filter(Role.name == role_data["name"]).first()
        if not role:
            role = Role(**role_data)
            db.add(role)
            db.commit()
            db.refresh(role)
            print(f"✓ Đã tạo role: {role_data['name']}")
        else:
            print(f"→ Role đã tồn tại: {role_data['name']}")
        created_roles[role_data["name"]] = role
    
    return created_roles


def create_permissions(db: Session):
    """Tạo permissions nếu chưa tồn tại"""
    print("\n=== Tạo Permissions ===")
    created_permissions = {}
    
    for perm_data in PERMISSIONS:
        permission = db.query(Permission).filter(Permission.name == perm_data["name"]).first()
        if not permission:
            permission = Permission(**perm_data)
            db.add(permission)
            db.commit()
            db.refresh(permission)
            print(f"✓ Đã tạo permission: {perm_data['name']}")
        else:
            print(f"→ Permission đã tồn tại: {perm_data['name']}")
        created_permissions[perm_data["name"]] = permission
    
    return created_permissions


def assign_permissions_to_roles(db: Session, roles: dict, permissions: dict):
    """Gán permissions cho roles"""
    print("\n=== Gán Permissions cho Roles ===")
    
    for role_name, permission_names in ROLE_PERMISSIONS.items():
        role = roles[role_name]
        # Refresh để có relationship
        db.refresh(role)
        assigned_count = 0
        
        for perm_name in permission_names:
            permission = permissions[perm_name]
            
            # Kiểm tra xem đã gán chưa bằng cách kiểm tra relationship
            if permission not in role.permissions:
                role.permissions.append(permission)
                assigned_count += 1
        
        if assigned_count > 0:
            db.commit()
            print(f"✓ Đã gán {assigned_count} permissions cho role: {role_name}")
        else:
            print(f"→ Role '{role_name}' đã có đầy đủ permissions")


def assign_roles_to_users(db: Session, roles: dict):
    """Gán roles cho users cũ chưa có roles"""
    print("\n=== Gán Roles cho Users ===")
    
    # Lấy tất cả users
    all_users = db.query(User).all()
    print(f"Tổng số users: {len(all_users)}")
    
    user_role = roles["user"]
    admin_role = roles["admin"]
    
    users_without_roles = []
    users_assigned_user_role = 0
    users_assigned_admin_role = 0
    
    for user in all_users:
        # Refresh để có relationship
        db.refresh(user)
        
        # Kiểm tra xem user đã có roles chưa
        if len(user.roles) == 0:
            users_without_roles.append(user)
        else:
            # User đã có roles, kiểm tra xem có cần gán admin role không
            if user.is_admin:
                # Kiểm tra xem đã có admin role chưa
                has_admin = any(role.name == "admin" for role in user.roles)
                
                if not has_admin:
                    user.roles.append(admin_role)
                    db.commit()
                    users_assigned_admin_role += 1
                    print(f"✓ Đã gán admin role cho user: {user.username} (ID: {user.id})")
    
    # Gán role "user" cho tất cả users chưa có roles
    for user in users_without_roles:
        user.roles.append(user_role)
        users_assigned_user_role += 1
        
        # Nếu user có is_admin = True, cũng gán admin role
        if user.is_admin:
            user.roles.append(admin_role)
            users_assigned_admin_role += 1
            print(f"✓ Đã gán user + admin roles cho user: {user.username} (ID: {user.id})")
        else:
            print(f"✓ Đã gán user role cho user: {user.username} (ID: {user.id})")
    
    if users_assigned_user_role > 0 or users_assigned_admin_role > 0:
        db.commit()
    
    print(f"\n→ Đã gán 'user' role cho {users_assigned_user_role} users")
    print(f"→ Đã gán 'admin' role cho {users_assigned_admin_role} users")
    print(f"→ Tổng cộng {len(users_without_roles)} users đã được gán roles")


def main():
    """Hàm chính"""
    print("=" * 60)
    print("KHỞI TẠO RBAC SYSTEM")
    print("=" * 60)
    
    db: Session = SessionLocal()
    
    try:
        # Bước 1: Tạo roles
        roles = create_roles(db)
        
        # Bước 2: Tạo permissions
        permissions = create_permissions(db)
        
        # Bước 3: Gán permissions cho roles
        assign_permissions_to_roles(db, roles, permissions)
        
        # Bước 4: Gán roles cho users cũ
        assign_roles_to_users(db, roles)
        
        print("\n" + "=" * 60)
        print("✓ HOÀN TẤT! RBAC system đã được khởi tạo thành công!")
        print("=" * 60)
        
        # Hiển thị thống kê
        print("\n=== THỐNG KÊ ===")
        total_roles = db.query(Role).count()
        total_permissions = db.query(Permission).count()
        total_users = db.query(User).count()
        # Đếm số user-role assignments
        total_user_roles = sum(len(user.roles) for user in db.query(User).all())
        
        print(f"Roles: {total_roles}")
        print(f"Permissions: {total_permissions}")
        print(f"Users: {total_users}")
        print(f"User-Role assignments: {total_user_roles}")
        
    except Exception as e:
        db.rollback()
        print(f"\n✗ LỖI: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()

