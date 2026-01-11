-- Migration: Add is_admin column to users table
-- Run this SQL script in MySQL Workbench to add is_admin column to existing database

USE rubik_master;

-- Add is_admin column if it doesn't exist
ALTER TABLE users 
ADD COLUMN is_admin BOOLEAN DEFAULT FALSE NOT NULL 
AFTER is_online;

-- Optional: Set first user as admin (uncomment if needed)
-- UPDATE users SET is_admin = TRUE WHERE id = 1;
