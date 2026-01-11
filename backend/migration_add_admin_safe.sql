-- Migration: Add is_admin column to users table (Safe version)
-- Run this SQL script in MySQL Workbench
-- Nếu cột đã tồn tại, script sẽ bỏ qua lỗi

USE rubik_master;

-- Check if column exists before adding
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'rubik_master' 
    AND TABLE_NAME = 'users' 
    AND COLUMN_NAME = 'is_admin'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE NOT NULL AFTER is_online',
    'SELECT "Column is_admin already exists" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Optional: Set first user as admin (uncomment if needed)
-- UPDATE users SET is_admin = TRUE WHERE id = 1;


