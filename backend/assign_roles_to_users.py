"""
Script chỉ gán roles cho users cũ chưa có roles
Chạy script này nếu roles và permissions đã được tạo rồi
Chạy: python assign_roles_to_users.py
"""

import sys
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.role import Role
from app.models.user import User


def assign_roles_to_existing_users():
    """Gán roles cho users cũ chưa có roles"""
    print("=" * 60)
    print("GÁN ROLES CHO USERS CŨ")
    print("=" * 60)
    
    db: Session = SessionLocal()
    
    try:
        # Lấy roles
        user_role = db.query(Role).filter(Role.name == "user").first()
        admin_role = db.query(Role).filter(Role.name == "admin").first()
        
        if not user_role:
            print("✗ LỖI: Role 'user' chưa được tạo. Vui lòng chạy init_rbac.py trước!")
            sys.exit(1)
        
        if not admin_role:
            print("✗ LỖI: Role 'admin' chưa được tạo. Vui lòng chạy init_rbac.py trước!")
            sys.exit(1)
        
        # Lấy tất cả users
        all_users = db.query(User).all()
        print(f"\nTổng số users: {len(all_users)}")
        
        users_assigned_user_role = 0
        users_assigned_admin_role = 0
        
        for user in all_users:
            # Refresh để có relationship
            db.refresh(user)
            
            # Kiểm tra xem user đã có roles chưa
            if len(user.roles) == 0:
                # User chưa có roles, gán role "user"
                user.roles.append(user_role)
                users_assigned_user_role += 1
                
                # Nếu user có is_admin = True, cũng gán admin role
                if user.is_admin:
                    user.roles.append(admin_role)
                    users_assigned_admin_role += 1
                    print(f"✓ Đã gán user + admin roles cho: {user.username} (ID: {user.id})")
                else:
                    print(f"✓ Đã gán user role cho: {user.username} (ID: {user.id})")
            else:
                # User đã có roles, kiểm tra xem có cần gán admin role không
                if user.is_admin:
                    has_admin = any(role.name == "admin" for role in user.roles)
                    if not has_admin:
                        user.roles.append(admin_role)
                        users_assigned_admin_role += 1
                        print(f"✓ Đã gán admin role cho: {user.username} (ID: {user.id})")
        
        if users_assigned_user_role > 0 or users_assigned_admin_role > 0:
            db.commit()
            print(f"\n✓ HOÀN TẤT!")
            print(f"→ Đã gán 'user' role cho {users_assigned_user_role} users")
            print(f"→ Đã gán 'admin' role cho {users_assigned_admin_role} users")
        else:
            print("\n→ Tất cả users đã có roles!")
        
    except Exception as e:
        db.rollback()
        print(f"\n✗ LỖI: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    assign_roles_to_existing_users()

