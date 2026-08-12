-- ============================================================================
-- Melody Mart - Authentication Module Schema (MySQL 8)
-- Production-Ready Database Schema for E-commerce Platform Authentication
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `melody_mart_auth` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `melody_mart_auth`;

-- Disable foreign key checks temporarily to drop tables in any order
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `refresh_tokens`;
DROP TABLE IF EXISTS `phone_otp`;
DROP TABLE IF EXISTS `email_otp`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. Table: users
-- ============================================================================
CREATE TABLE `users` (
    `id` BIGINT AUTO_INCREMENT,
    `username` VARCHAR(50) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `first_name` VARCHAR(50) NOT NULL,
    `last_name` VARCHAR(50) NOT NULL,
    
    -- Generated columns (MySQL 8) to avoid data redundancy and ensure single source of truth
    `full_name` VARCHAR(101) GENERATED ALWAYS AS (CONCAT(`first_name`, ' ', `last_name`)) STORED,
    
    `phone_number` VARCHAR(20) DEFAULT NULL,
    `is_email_verified` TINYINT(1) NOT NULL DEFAULT 0,
    `is_phone_verified` TINYINT(1) NOT NULL DEFAULT 0,
    `gender` VARCHAR(20) DEFAULT NULL,
    `date_of_birth` DATE DEFAULT NULL,
    `profile_image_url` VARCHAR(255) DEFAULT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING_VERIFICATION',
    `role` VARCHAR(30) NOT NULL DEFAULT 'ROLE_CUSTOMER',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `uk_users_username` UNIQUE (`username`),
    CONSTRAINT `uk_users_email` UNIQUE (`email`),
    CONSTRAINT `uk_users_phone` UNIQUE (`phone_number`),
    
    -- Indexes for fast searches during login (which supports Username OR Email) and status check
    INDEX `idx_users_username` (`username`),
    INDEX `idx_users_email` (`email`),
    INDEX `idx_users_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. Table: email_otp
-- ============================================================================
CREATE TABLE `email_otp` (
    `id` BIGINT AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `otp_code` VARCHAR(6) NOT NULL,
    
    -- Purpose allows using this table for registration, password reset, or multi-factor authentication
    `purpose` VARCHAR(30) NOT NULL,
    `expiry_time` TIMESTAMP NOT NULL,
    `is_used` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_email_otp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    
    -- Composite index for fast lookup of active tokens during verification
    INDEX `idx_email_otp_lookup` (`user_id`, `otp_code`, `purpose`, `is_used`),
    INDEX `idx_email_otp_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. Table: phone_otp
-- ============================================================================
CREATE TABLE `phone_otp` (
    `id` BIGINT AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `otp_code` VARCHAR(6) NOT NULL,
    
    -- Purpose allows using this table for registration, password reset, or SMS-based MFA
    `purpose` VARCHAR(30) NOT NULL,
    `expiry_time` TIMESTAMP NOT NULL,
    `is_used` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_phone_otp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    
    -- Composite index for fast lookup of active OTP tokens during verification
    INDEX `idx_phone_otp_lookup` (`user_id`, `otp_code`, `purpose`, `is_used`),
    INDEX `idx_phone_otp_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. Table: refresh_tokens
-- ============================================================================
CREATE TABLE `refresh_tokens` (
    `id` BIGINT AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `token` VARCHAR(255) NOT NULL,
    `expiry_date` TIMESTAMP NOT NULL,
    `is_revoked` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `uk_refresh_tokens_token` UNIQUE (`token`),
    CONSTRAINT `fk_refresh_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    
    INDEX `idx_refresh_tokens_token` (`token`),
    INDEX `idx_refresh_tokens_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Insert Seed Data (Example Records for testing)
-- ============================================================================

-- Seed standard user (password_hash is BCrypt representation of 'Roopas@2308')
INSERT INTO `users` (
    `id`, `username`, `email`, `password_hash`, `first_name`, `last_name`, `phone_number`, 
    `is_email_verified`, `is_phone_verified`, `gender`, `date_of_birth`, `profile_image_url`, 
    `status`, `role`
) VALUES (
    1, 
    'roopa_mart', 
    'roopa@example.com', 
    '$2a$10$w8.4b/1.9UoX1gN9Hwq3Oegc459W969a5pU2Y1G8sXw7eZ1P1g6G.', -- BCrypt hash
    'Roopa', 
    'S', 
    '+919876543210', 
    1, 
    1, 
    'FEMALE', 
    '1995-08-23', 
    'https://cdn.melodymart.com/profiles/roopa_mart.jpg', 
    'ACTIVE', 
    'ROLE_ADMIN'
);

-- Seed pending customer (password_hash is BCrypt representation of 'CustomerPassword!123')
INSERT INTO `users` (
    `id`, `username`, `email`, `password_hash`, `first_name`, `last_name`, `phone_number`, 
    `is_email_verified`, `is_phone_verified`, `gender`, `date_of_birth`, `profile_image_url`, 
    `status`, `role`
) VALUES (
    2, 
    'john_guitar', 
    'john.doe@example.com', 
    '$2a$10$vO.mX4C15t9.Ff8s1J0f9OGL7YlC23lqD8sXw7eZ1P1g6G.xyz123', -- BCrypt hash
    'John', 
    'Doe', 
    '+12025550143', 
    0, 
    0, 
    'MALE', 
    '1998-04-12', 
    NULL, 
    'PENDING_VERIFICATION', 
    'ROLE_CUSTOMER'
);

-- Seed email OTP for verification
INSERT INTO `email_otp` (`id`, `user_id`, `otp_code`, `purpose`, `expiry_time`, `is_used`)
VALUES (1, 2, '583920', 'REGISTRATION_VERIFICATION', DATE_ADD(NOW(), INTERVAL 15 MINUTE), 0);

-- Seed phone OTP for verification
INSERT INTO `phone_otp` (`id`, `user_id`, `otp_code`, `purpose`, `expiry_time`, `is_used`)
VALUES (1, 2, '910384', 'REGISTRATION_VERIFICATION', DATE_ADD(NOW(), INTERVAL 15 MINUTE), 0);

-- Seed active refresh token for root admin
INSERT INTO `refresh_tokens` (`id`, `user_id`, `token`, `expiry_date`, `is_revoked`)
VALUES (1, 1, '8f276cd8-5b4d-4ba6-bc0f-15c2ee571d8a', DATE_ADD(NOW(), INTERVAL 7 DAY), 0);
