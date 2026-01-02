# Hướng dẫn khởi tạo RBAC System

## Cách chạy script khởi tạo RBAC

### Bước 1: Đảm bảo database đã có cột `is_admin`

Nếu chưa chạy migration, chạy SQL sau trong MySQL Workbench:

```sql
USE rubik_master;
ALTER TABLE users 
ADD COLUMN is_admin BOOLEAN DEFAULT FALSE NOT NULL 
AFTER is_online;
```

### Bước 2: Chạy script Python

Từ thư mục `backend`, chạy:

```bash
python init_rbac.py
```

Hoặc nếu dùng virtual environment:

```bash
# Windows
.venv\Scripts\activate
python init_rbac.py

# Linux/Mac
source .venv/bin/activate
python init_rbac.py
```

## Script sẽ làm gì?

1. **Tạo Roles**: 
   - `admin`: Full system access
   - `moderator`: Moderate content and users
   - `user`: Standard user access

2. **Tạo Permissions**: Tất cả permissions cần thiết cho hệ thống

3. **Gán Permissions cho Roles**:
   - Admin: Tất cả permissions
   - Moderator: View users, ban users, view/delete matches, view/delete messages, view statistics
   - User: View users, view/create matches, view messages

4. **Gán Roles cho Users**:
   - Tất cả users chưa có roles → gán role "user"
   - Users có `is_admin = TRUE` → gán thêm role "admin"

## Kết quả mong đợi

Sau khi chạy xong, bạn sẽ thấy:
- ✓ Đã tạo 3 roles
- ✓ Đã tạo 15 permissions
- ✓ Đã gán permissions cho các roles
- ✓ Đã gán roles cho tất cả users

## Lưu ý

- Script có thể chạy nhiều lần an toàn (idempotent)
- Nếu roles/permissions đã tồn tại, script sẽ bỏ qua
- Script chỉ gán roles cho users chưa có roles

