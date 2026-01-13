from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel
from app.database import get_db
from typing import Dict, Any, List, Optional
from app.utils.rbac_dependencies import require_permission
from app.utils.permissions import Permissions
from app.utils.dependencies import get_admin_user
from app.services.admin_service import AdminService
from app.schemas.user import UserResponse
import random
from datetime import datetime
router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/tables")
def show_tables(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị tất cả bảng"""
    try:
        result = db.execute(text("SHOW TABLES"))
        tables = [row[0] for row in result.fetchall()]
        return {"tables": tables}
    except Exception as e:
        return {"error": str(e)}

@router.get("/users")
def show_users(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị users"""
    try:
        result = db.execute(text("SELECT id, username, email, is_admin, elo_rating, created_at FROM users ORDER BY id DESC LIMIT 20"))
        users = []
        for row in result.fetchall():
            users.append({
                "id": row[0],
                "username": row[1], 
                "email": row[2],
                "is_admin": bool(row[3]) if row[3] is not None else False,
                "elo_rating": row[4],
                "created_at": str(row[5]) if row[5] else None
            })
        return {"users": users}
    except Exception as e:
        return {"error": str(e)}

@router.get("/messages")
def show_messages(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị messages"""
    try:
        result = db.execute(text("""
            SELECT m.id, m.sender_id, m.receiver_id, m.message, m.timestamp,
                   u1.username as sender_name, u2.username as receiver_name
            FROM messages m
            LEFT JOIN users u1 ON m.sender_id = u1.id  
            LEFT JOIN users u2 ON m.receiver_id = u2.id
            ORDER BY m.timestamp DESC LIMIT 50
        """))
        
        messages = []
        for row in result.fetchall():
            messages.append({
                "id": row[0],
                "sender_id": row[1],
                "receiver_id": row[2], 
                "message": row[3],
                "timestamp": str(row[4]) if row[4] else None,
                "sender_name": row[5],
                "receiver_name": row[6]
            })
        return {"messages": messages}
    except Exception as e:
        return {"error": str(e)}

@router.get("/friends")
def show_friends(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị friends"""
    try:
        result = db.execute(text("""
            SELECT f.id, f.user_id, f.friend_id, f.status, f.created_at,
                   u1.username as user_name, u2.username as friend_name
            FROM friends f
            LEFT JOIN users u1 ON f.user_id = u1.id
            LEFT JOIN users u2 ON f.friend_id = u2.id  
            ORDER BY f.created_at DESC LIMIT 50
        """))
        
        friends = []
        for row in result.fetchall():
            friends.append({
                "id": row[0],
                "user_id": row[1],
                "friend_id": row[2],
                "status": row[3],
                "created_at": str(row[4]) if row[4] else None,
                "user_name": row[5],
                "friend_name": row[6]
            })
        return {"friends": friends}
    except Exception as e:
        return {"error": str(e)}

@router.get("/matches")
def show_matches(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị các trận đấu"""
    try:
        result = db.execute(text("""
            SELECT id, match_id, player1_id, player2_id, status, scramble, created_at,
                   player1_time, player2_time, winner_id
            FROM matches ORDER BY created_at DESC LIMIT 20
        """))
        
        matches = []
        for row in result.fetchall():
            scramble_count = len(row[5].split()) if row[5] else 0
            matches.append({
                "id": row[0],
                "match_id": row[1],
                "player1_id": row[2],
                "player2_id": row[3], 
                "status": row[4],
                "scramble": row[5],
                "scramble_moves_count": scramble_count,
                "created_at": str(row[6]) if row[6] else None,
                "player1_time": row[7],
                "player2_time": row[8],
                "winner_id": row[9]
            })
        return {"matches": matches}
    except Exception as e:
        return {"error": str(e)}

@router.get("/permissions")
def show_permissions(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị tất cả permissions"""
    try:
        result = db.execute(text("SELECT * FROM permissions ORDER BY id DESC LIMIT 50"))
        permissions = []
        for row in result.fetchall():
            permissions.append({
                "id": row[0],
                "name": row[1] if len(row) > 1 else None,
                "description": row[2] if len(row) > 2 else None,
                "created_at": str(row[3]) if len(row) > 3 and row[3] else None
            })
        return {"permissions": permissions}
    except Exception as e:
        return {"error": str(e)}

@router.get("/roles")
def show_roles(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị tất cả roles"""
    try:
        result = db.execute(text("SELECT * FROM roles ORDER BY id DESC LIMIT 50"))
        roles = []
        for row in result.fetchall():
            roles.append({
                "id": row[0],
                "name": row[1] if len(row) > 1 else None,
                "description": row[2] if len(row) > 2 else None,
                "created_at": str(row[3]) if len(row) > 3 and row[3] else None
            })
        return {"roles": roles}
    except Exception as e:
        return {"error": str(e)}

@router.get("/user-roles")
def show_user_roles(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị user-roles mapping"""
    try:
        result = db.execute(text("""
            SELECT ur.*, u.username, r.name as role_name
            FROM user_roles ur
            LEFT JOIN users u ON ur.user_id = u.id
            LEFT JOIN roles r ON ur.role_id = r.id
            ORDER BY ur.id DESC LIMIT 50
        """))
        
        user_roles = []
        for row in result.fetchall():
            user_roles.append({
                "id": row[0],
                "user_id": row[1],
                "role_id": row[2],
                "assigned_at": str(row[3]) if len(row) > 3 and row[3] else None,
                "username": row[4] if len(row) > 4 else None,
                "role_name": row[5] if len(row) > 5 else None
            })
        return {"user_roles": user_roles}
    except Exception as e:
        return {"error": str(e)}

@router.get("/role-permissions")
def show_role_permissions(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị role-permissions mapping"""
    try:
        result = db.execute(text("""
            SELECT rp.*, r.name as role_name, p.name as permission_name
            FROM role_permissions rp
            LEFT JOIN roles r ON rp.role_id = r.id
            LEFT JOIN permissions p ON rp.permission_id = p.id
            ORDER BY rp.id DESC LIMIT 50
        """))
        
        role_permissions = []
        for row in result.fetchall():
            role_permissions.append({
                "id": row[0],
                "role_id": row[1],
                "permission_id": row[2],
                "granted_at": str(row[3]) if len(row) > 3 and row[3] else None,
                "role_name": row[4] if len(row) > 4 else None,
                "permission_name": row[5] if len(row) > 5 else None
            })
        return {"role_permissions": role_permissions}
    except Exception as e:
        return {"error": str(e)}

@router.get("/all-tables-info")
def show_all_tables_info(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Hiển thị thông tin tất cả bảng liên quan đến quyền"""
    try:
        # Users
        users_result = db.execute(text("SELECT id, username, email, is_admin FROM users LIMIT 10"))
        users = [dict(zip(['id', 'username', 'email', 'is_admin'], row)) for row in users_result.fetchall()]
        
        # Roles  
        roles_result = db.execute(text("SELECT * FROM roles"))
        roles = [dict(zip(['id', 'name', 'description', 'created_at'], row)) for row in roles_result.fetchall()]
        
        # Permissions
        permissions_result = db.execute(text("SELECT * FROM permissions"))
        permissions = [dict(zip(['id', 'name', 'description', 'created_at'], row)) for row in permissions_result.fetchall()]
        
        # Role Permissions
        role_perms_result = db.execute(text("""
            SELECT rp.id, rp.role_id, rp.permission_id, r.name as role_name, p.name as permission_name
            FROM role_permissions rp
            LEFT JOIN roles r ON rp.role_id = r.id
            LEFT JOIN permissions p ON rp.permission_id = p.id
        """))
        role_permissions = [dict(zip(['id', 'role_id', 'permission_id', 'role_name', 'permission_name'], row)) 
                           for row in role_perms_result.fetchall()]
        
        # User Roles
        user_roles_result = db.execute(text("""
            SELECT ur.id, ur.user_id, ur.role_id, u.username, r.name as role_name
            FROM user_roles ur
            LEFT JOIN users u ON ur.user_id = u.id
            LEFT JOIN roles r ON ur.role_id = r.id
        """))
        user_roles = [dict(zip(['id', 'user_id', 'role_id', 'username', 'role_name'], row)) 
                     for row in user_roles_result.fetchall()]
        
        return {
            "users": users,
            "roles": roles,
            "permissions": permissions,
            "role_permissions": role_permissions,
            "user_roles": user_roles
        }
    except Exception as e:
        return {"error": str(e)}

@router.post("/setup-admin-system")
def setup_admin_system(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Tạo role và permission admin cơ bản"""
    try:
        # 1. Tạo role Admin nếu chưa có
        admin_role_check = db.execute(text("SELECT id FROM roles WHERE name = 'admin'")).fetchone()
        if not admin_role_check:
            db.execute(text("INSERT INTO roles (name, description, created_at) VALUES ('admin', 'Full system administrator', NOW())"))
            db.commit()
        
        admin_role = db.execute(text("SELECT id FROM roles WHERE name = 'admin'")).fetchone()
        admin_role_id = admin_role[0]
        
        # 2. Tạo các permission cơ bản
        basic_permissions = [
            ('manage_users', 'Can manage users'),
            ('manage_matches', 'Can manage matches'),
            ('view_all_data', 'Can view all system data'),
            ('delete_messages', 'Can delete messages'),
            ('ban_users', 'Can ban/unban users'),
            ('manage_rankings', 'Can modify rankings'),
            ('admin_panel', 'Can access admin panel'),
            ('system_config', 'Can modify system configuration')
        ]
        
        created_perms = []
        for perm_name, perm_desc in basic_permissions:
            existing = db.execute(text("SELECT id FROM permissions WHERE name = :name"), {"name": perm_name}).fetchone()
            if not existing:
                db.execute(text("INSERT INTO permissions (name, description, created_at) VALUES (:name, :desc, NOW())"), 
                          {"name": perm_name, "desc": perm_desc})
                created_perms.append(perm_name)
        
        db.commit()
        
        # 3. Gán tất cả permission cho role admin
        all_perms = db.execute(text("SELECT id FROM permissions")).fetchall()
        assigned_perms = 0
        for perm in all_perms:
            perm_id = perm[0]
            existing = db.execute(text("SELECT id FROM role_permissions WHERE role_id = :role_id AND permission_id = :perm_id"), 
                                {"role_id": admin_role_id, "perm_id": perm_id}).fetchone()
            if not existing:
                db.execute(text("INSERT INTO role_permissions (role_id, permission_id, granted_at) VALUES (:role_id, :perm_id, NOW())"), 
                          {"role_id": admin_role_id, "perm_id": perm_id})
                assigned_perms += 1
        
        db.commit()
        
        return {
            "message": "Admin system setup completed",
            "admin_role_id": admin_role_id,
            "created_permissions": created_perms,
            "assigned_permissions": assigned_perms
        }
        
    except Exception as e:
        return {"error": str(e)}

@router.post("/make-user-admin/{user_id}")
def make_user_admin(user_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Gán role admin cho user"""
    try:
        # 1. Cập nhật is_admin trong bảng users
        db.execute(text("UPDATE users SET is_admin = 1 WHERE id = :user_id"), {"user_id": user_id})
        
        # 2. Lấy admin role ID
        admin_role = db.execute(text("SELECT id FROM roles WHERE name = 'admin'")).fetchone()
        if not admin_role:
            return {"error": "Admin role not found. Run /admin/setup-admin-system first"}
        
        admin_role_id = admin_role[0]
        
        # 3. Gán role admin cho user (nếu chưa có)
        existing = db.execute(text("SELECT id FROM user_roles WHERE user_id = :user_id AND role_id = :role_id"), 
                            {"user_id": user_id, "role_id": admin_role_id}).fetchone()
        
        if not existing:
            db.execute(text("INSERT INTO user_roles (user_id, role_id, assigned_at) VALUES (:user_id, :role_id, NOW())"), 
                      {"user_id": user_id, "role_id": admin_role_id})
        
        db.commit()
        
        # 4. Verify user info
        user_info = db.execute(text("""
            SELECT u.id, u.username, u.is_admin
            FROM users u
            WHERE u.id = :user_id
        """), {"user_id": user_id}).fetchone()
        
        if user_info:
            return {
                "message": f"User {user_id} is now admin",
                "user": {
                    "id": user_info[0],
                    "username": user_info[1],
                    "is_admin": bool(user_info[2])
                }
            }
        else:
            return {"error": "User not found"}
        
    except Exception as e:
        return {"error": str(e)}

@router.get("/user-permissions/{user_id}")
def get_user_permissions(user_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Lấy tất cả quyền của user"""
    try:
        result = db.execute(text("""
            SELECT DISTINCT p.id, p.name, p.description
            FROM permissions p
            JOIN role_permissions rp ON p.id = rp.permission_id
            JOIN user_roles ur ON rp.role_id = ur.role_id
            WHERE ur.user_id = :user_id
        """), {"user_id": user_id})
        
        permissions = []
        for row in result.fetchall():
            permissions.append({
                "id": row[0],
                "name": row[1],
                "description": row[2]
            })
        
        return {"user_id": user_id, "permissions": permissions}
    except Exception as e:
        return {"error": str(e)}

@router.patch("/update-scrambles/{match_id}")
def update_scrambles(match_id: int, new_count: int = 3, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Cập nhật số moves trong scramble của trận đấu"""
    try:
        # Tạo scramble ngắn với số moves tùy chỉnh
        def generate_scramble(moves_count: int = 3) -> str:
            moves = ["R", "R'", "R2", "L", "L'", "L2", "U", "U'", "U2", "D", "D'", "D2", "F", "F'", "F2", "B", "B'", "B2"]
            
            scramble_moves = []
            last_face = ""
            
            for _ in range(moves_count):
                available_moves = [m for m in moves if m[0] != last_face]
                move = random.choice(available_moves)
                scramble_moves.append(move)
                last_face = move[0]
            
            return " ".join(scramble_moves)
        
        # Tạo scramble mới
        new_scramble = generate_scramble(new_count)
        
        # Update database
        result = db.execute(text("UPDATE matches SET scramble = :scramble WHERE id = :match_id"), 
                   {"scramble": new_scramble, "match_id": match_id})
        db.commit()
        
        if result.rowcount > 0:
            return {"message": f"Updated match {match_id} with new {new_count}-move scramble", "new_scramble": new_scramble}
        else:
            return {"error": "Match not found"}
            
    except Exception as e:
        return {"error": str(e)}

@router.patch("/update-all-scrambles")
def update_all_scrambles(new_count: int = 3, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Cập nhật tất cả scramble về số moves ngắn hơn"""
    try:
        def generate_scramble(moves_count: int = 3) -> str:
            moves = ["R", "R'", "R2", "L", "L'", "L2", "U", "U'", "U2", "D", "D'", "D2", "F", "F'", "F2", "B", "B'", "B2"]
            
            scramble_moves = []
            last_face = ""
            
            for _ in range(moves_count):
                available_moves = [m for m in moves if m[0] != last_face]
                move = random.choice(available_moves)
                scramble_moves.append(move)
                last_face = move[0]
            
            return " ".join(scramble_moves)
        
        result = db.execute(text("SELECT id FROM matches WHERE scramble IS NOT NULL AND status = 'active'"))
        matches = result.fetchall()
        
        updated = 0
        for match in matches:
            match_id = match[0]
            new_scramble = generate_scramble(new_count)
            db.execute(text("UPDATE matches SET scramble = :scramble WHERE id = :match_id"), 
                       {"scramble": new_scramble, "match_id": match_id})
            updated += 1
        
        db.commit()
        return {"message": f"Updated {updated} matches to {new_count}-move scrambles"}
        
    except Exception as e:
        return {"error": str(e)}

@router.delete("/delete-match/{match_id}")
def delete_match(match_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Xóa trận đấu"""
    try:
        result = db.execute(text("DELETE FROM matches WHERE id = :match_id"), {"match_id": match_id})
        db.commit()
        
        if result.rowcount > 0:
            return {"message": f"Deleted match {match_id}"}
        else:
            return {"error": "Match not found"}
    except Exception as e:
        return {"error": str(e)}

@router.patch("/ban-user/{user_id}")
def ban_user(user_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Ban user (set is_active = false hoặc thêm field banned)"""
    try:
        # Thêm field banned nếu chưa có, hoặc dùng is_active
        db.execute(text("UPDATE users SET is_admin = 0 WHERE id = :user_id"), {"user_id": user_id})
        db.commit()
        
        return {"message": f"Banned user {user_id}"}
    except Exception as e:
        return {"error": str(e)}

@router.post("/grant-full-admin/{user_id}")
def grant_full_admin(user_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Cấp toàn bộ quyền admin cho user trong 1 lần"""
    try:
        # 1. Setup admin system
        admin_role_check = db.execute(text("SELECT id FROM roles WHERE name = 'admin'")).fetchone()
        if not admin_role_check:
            db.execute(text("INSERT INTO roles (name, description, created_at) VALUES ('admin', 'Full system administrator', NOW())"))
            db.commit()
        
        admin_role = db.execute(text("SELECT id FROM roles WHERE name = 'admin'")).fetchone()
        admin_role_id = admin_role[0]
        
        # 2. Tạo tất cả permissions
        all_permissions = [
            ('manage_users', 'Can manage users'),
            ('manage_matches', 'Can manage matches'),
            ('view_all_data', 'Can view all system data'),
            ('delete_messages', 'Can delete messages'),
            ('ban_users', 'Can ban/unban users'),
            ('manage_rankings', 'Can modify rankings'),
            ('admin_panel', 'Can access admin panel'),
            ('system_config', 'Can modify system configuration'),
            ('full_access', 'Full system access'),
            ('super_admin', 'Super administrator'),
            ('manage_roles', 'Can manage roles and permissions'),
            ('view_logs', 'Can view system logs'),
            ('backup_restore', 'Can backup and restore data')
        ]
        
        created_perms = []
        for perm_name, perm_desc in all_permissions:
            existing = db.execute(text("SELECT id FROM permissions WHERE name = :name"), {"name": perm_name}).fetchone()
            if not existing:
                db.execute(text("INSERT INTO permissions (name, description, created_at) VALUES (:name, :desc, NOW())"), 
                          {"name": perm_name, "desc": perm_desc})
                created_perms.append(perm_name)
        
        db.commit()
        
        # 3. Gán tất cả permission cho role admin
        all_perms = db.execute(text("SELECT id FROM permissions")).fetchall()
        assigned_perms = 0
        for perm in all_perms:
            perm_id = perm[0]
            existing = db.execute(text("SELECT id FROM role_permissions WHERE role_id = :role_id AND permission_id = :perm_id"), 
                                {"role_id": admin_role_id, "perm_id": perm_id}).fetchone()
            if not existing:
                db.execute(text("INSERT INTO role_permissions (role_id, permission_id, granted_at) VALUES (:role_id, :perm_id, NOW())"), 
                          {"role_id": admin_role_id, "perm_id": perm_id})
                assigned_perms += 1
        
        db.commit()
        
        # 4. Set user làm admin
        db.execute(text("UPDATE users SET is_admin = 1 WHERE id = :user_id"), {"user_id": user_id})
        
        # 5. Gán role admin cho user
        existing_user_role = db.execute(text("SELECT id FROM user_roles WHERE user_id = :user_id AND role_id = :role_id"), 
                            {"user_id": user_id, "role_id": admin_role_id}).fetchone()
        
        if not existing_user_role:
            db.execute(text("INSERT INTO user_roles (user_id, role_id, assigned_at) VALUES (:user_id, :role_id, NOW())"), 
                      {"user_id": user_id, "role_id": admin_role_id})
        
        db.commit()
        
        # 6. Verify tất cả permissions của user
        user_permissions = db.execute(text("""
            SELECT DISTINCT p.name
            FROM permissions p
            JOIN role_permissions rp ON p.id = rp.permission_id
            JOIN user_roles ur ON rp.role_id = ur.role_id
            WHERE ur.user_id = :user_id
        """), {"user_id": user_id}).fetchall()
        
        permission_names = [perm[0] for perm in user_permissions]
        
        # 7. Get user info
        user_info = db.execute(text("SELECT id, username, email, is_admin FROM users WHERE id = :user_id"), 
                              {"user_id": user_id}).fetchone()
        
        return {
            "message": f"FULL ADMIN ACCESS granted to user {user_id}",
            "user": {
                "id": user_info[0],
                "username": user_info[1],
                "email": user_info[2],
                "is_admin": bool(user_info[3])
            },
            "total_permissions": len(permission_names),
            "permissions": permission_names,
            "created_new_permissions": created_perms,
            "status": "SUCCESS - User now has FULL SYSTEM ACCESS"
        }
        
    except Exception as e:
        return {"error": str(e)}

@router.get("/stats")
def get_stats(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Thống kê tổng quan hệ thống"""
    try:
        # Count users
        users_count = db.execute(text("SELECT COUNT(*) FROM users")).scalar()
        
        # Count matches
        matches_count = db.execute(text("SELECT COUNT(*) FROM matches")).scalar()
        
        # Count messages
        messages_count = db.execute(text("SELECT COUNT(*) FROM messages")).scalar()
        
        # Count friends
        friends_count = db.execute(text("SELECT COUNT(*) FROM friends")).scalar()
        
        # Active matches
        active_matches = db.execute(text("SELECT COUNT(*) FROM matches WHERE status = 'active'")).scalar()
        
        return {
            "total_users": users_count,
            "total_matches": matches_count,
            "total_messages": messages_count,
            "total_friendships": friends_count,
            "active_matches": active_matches
        }
    except Exception as e:
        return {"error": str(e)}
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

