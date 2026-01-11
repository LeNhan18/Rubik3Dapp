-- ============================================
-- MIGRATION TỔNG HỢP - CHẠY TẤT CẢ MỘT LẦN
-- ============================================
-- Copy và chạy toàn bộ script này trong MySQL Workbench
-- ============================================

USE rubik_master;

-- ============================================
-- STEP 1: Add is_admin column to users table
-- ============================================
-- Note: Nếu cột đã tồn tại, bỏ qua lỗi hoặc comment dòng này
ALTER TABLE users 
ADD COLUMN is_admin BOOLEAN DEFAULT FALSE NOT NULL 
AFTER is_online;

-- ============================================
-- STEP 2: Create RBAC tables (Roles, Permissions)
-- ============================================

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(255) DEFAULT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_resource (resource)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Role-Permissions association table
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User-Roles association table
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- STEP 3: Insert default roles
-- ============================================
INSERT INTO roles (name, description) VALUES
('admin', 'Full system access'),
('moderator', 'Moderate content and users'),
('user', 'Standard user access')
ON DUPLICATE KEY UPDATE name=name;

-- ============================================
-- STEP 4: Insert default permissions
-- ============================================
INSERT INTO permissions (name, description, resource, action) VALUES
-- User permissions
('users.view', 'View users', 'users', 'view'),
('users.create', 'Create users', 'users', 'create'),
('users.update', 'Update users', 'users', 'update'),
('users.delete', 'Delete users', 'users', 'delete'),
('users.manage_roles', 'Manage user roles', 'users', 'manage_roles'),
('users.ban', 'Ban users', 'users', 'ban'),

-- Match permissions
('matches.view', 'View matches', 'matches', 'view'),
('matches.create', 'Create matches', 'matches', 'create'),
('matches.update', 'Update matches', 'matches', 'update'),
('matches.delete', 'Delete matches', 'matches', 'delete'),

-- Message permissions
('messages.view', 'View messages', 'messages', 'view'),
('messages.delete', 'Delete messages', 'messages', 'delete'),

-- Statistics permissions
('statistics.view', 'View statistics', 'statistics', 'view'),

-- System permissions
('system.manage_roles', 'Manage roles and permissions', 'system', 'manage_roles'),
('system.manage_permissions', 'Manage permissions', 'system', 'manage_permissions')
ON DUPLICATE KEY UPDATE name=name;

-- ============================================
-- STEP 5: Assign permissions to roles
-- ============================================

-- Assign ALL permissions to admin role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'admin'
ON DUPLICATE KEY UPDATE role_id=role_id;

-- Assign basic permissions to moderator role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'moderator'
AND p.name IN (
    'users.view',
    'users.ban',
    'matches.view',
    'matches.delete',
    'messages.view',
    'messages.delete',
    'statistics.view'
)
ON DUPLICATE KEY UPDATE role_id=role_id;

-- Assign basic permissions to user role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'user'
AND p.name IN (
    'users.view',
    'matches.view',
    'matches.create',
    'messages.view'
)
ON DUPLICATE KEY UPDATE role_id=role_id;

-- ============================================
-- STEP 6: Assign roles to existing users
-- ============================================

-- Assign 'user' role to all existing users
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u, roles r
WHERE r.name = 'user'
ON DUPLICATE KEY UPDATE user_id=user_id;

-- Assign 'admin' role to users with is_admin = TRUE
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u, roles r
WHERE u.is_admin = TRUE AND r.name = 'admin'
ON DUPLICATE KEY UPDATE user_id=user_id;

-- ============================================
-- MIGRATION HOÀN TẤT!
-- ============================================
-- Kiểm tra kết quả:
-- SELECT * FROM roles;
-- SELECT * FROM permissions;
-- SELECT * FROM role_permissions;
-- SELECT * FROM user_roles;
-- ============================================

