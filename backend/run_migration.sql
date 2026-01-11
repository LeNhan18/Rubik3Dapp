-- Migration: Add is_admin column to users table
-- Run this SQL script to add is_admin column to existing database

USE rubik_master;

-- Check if column exists, if not add it
SET @dbname = DATABASE();
SET @tablename = "users";
SET @columnname = "is_admin";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 'Column already exists.' AS result;",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " BOOLEAN DEFAULT FALSE NOT NULL AFTER is_online;")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Set first user as admin (optional - uncomment if needed)
-- UPDATE users SET is_admin = TRUE WHERE id = 1;


