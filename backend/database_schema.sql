-- Rubik Master Database Schema
-- MySQL 8.0+

CREATE DATABASE IF NOT EXISTS rubik_master CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE rubik_master;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255) DEFAULT NULL,
    total_wins INT DEFAULT 0,
    total_losses INT DEFAULT 0,
    total_draws INT DEFAULT 0,
    average_time DECIMAL(10, 2) DEFAULT NULL,
    best_time INT DEFAULT NULL COMMENT 'milliseconds',
    elo_rating INT DEFAULT 1000 NOT NULL,
    is_online BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    last_seen DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_is_online (is_online)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Friendships table
CREATE TABLE IF NOT EXISTS friendships (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user1_id INT NOT NULL,
    user2_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'blocked') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_friendship (user1_id, user2_id),
    INDEX idx_user1 (user1_id),
    INDEX idx_user2 (user2_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Matches table
CREATE TABLE IF NOT EXISTS matches (
    id INT PRIMARY KEY AUTO_INCREMENT,
    match_id VARCHAR(36) UNIQUE NOT NULL,
    player1_id INT NOT NULL,
    player2_id INT NOT NULL,
    scramble TEXT NOT NULL,
    status ENUM('waiting', 'active', 'completed', 'cancelled') DEFAULT 'waiting',
    player1_time INT DEFAULT NULL COMMENT 'milliseconds',
    player2_time INT DEFAULT NULL COMMENT 'milliseconds',
    winner_id INT DEFAULT NULL,
    is_draw BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME DEFAULT NULL,
    completed_at DATETIME DEFAULT NULL,
    FOREIGN KEY (player1_id) REFERENCES users(id),
    FOREIGN KEY (player2_id) REFERENCES users(id),
    FOREIGN KEY (winner_id) REFERENCES users(id),
    INDEX idx_match_id (match_id),
    INDEX idx_player1 (player1_id),
    INDEX idx_player2 (player2_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Chat messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    match_id VARCHAR(36) NOT NULL,
    sender_id INT NOT NULL,
    content TEXT NOT NULL,
    message_type ENUM('text', 'system') DEFAULT 'text',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    INDEX idx_match_id (match_id),
    INDEX idx_created_at (created_at),
    INDEX idx_sender (sender_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Match invitations table
CREATE TABLE IF NOT EXISTS match_invitations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    inviter_id INT NOT NULL,
    invitee_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'rejected', 'expired') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME DEFAULT NULL,
    FOREIGN KEY (inviter_id) REFERENCES users(id),
    FOREIGN KEY (invitee_id) REFERENCES users(id),
    INDEX idx_inviter (inviter_id),
    INDEX idx_invitee (invitee_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration: Add ELO rating column to users table
-- Run this SQL script to add elo_rating column to existing database

ALTER TABLE users
ADD COLUMN elo_rating INT DEFAULT 1000 NOT NULL
AFTER best_time;

-- Update existing users to have default ELO rating of 1000
UPDATE users SET elo_rating = 1000 WHERE elo_rating IS NULL;


