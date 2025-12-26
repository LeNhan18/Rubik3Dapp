-- Migration: Add ELO rating column to users table
-- Run this SQL script to add elo_rating column to existing database

ALTER TABLE users 
ADD COLUMN elo_rating INT DEFAULT 1000 NOT NULL 
AFTER best_time;

-- Update existing users to have default ELO rating of 1000
UPDATE users SET elo_rating = 1000 WHERE elo_rating IS NULL;

