-- ============================================================================
-- MelodyMart - Shopping Module Schema (MySQL 8)
-- Production-Ready Database Schema for E-commerce Wishlist & Cart Management
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `melodymart_shopping` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `melodymart_shopping`;

-- Disable foreign key checks temporarily to drop tables in any order
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `cart_items`;
DROP TABLE IF EXISTS `cart`;
DROP TABLE IF EXISTS `wishlist`;

-- SKELETON REFERENCE TABLES
-- Note: InnoDB requires foreign keys to refer to tables within the same database schema.
-- In a production environment, if these modules are deployed in a single database,
-- these tables will already exist. We define minimal skeletons here for standalone script validation.
CREATE TABLE IF NOT EXISTS `users` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL,
    `email` VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `products` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL,
    `sku` VARCHAR(100) NOT NULL,
    `price` DECIMAL(12, 2) NOT NULL
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. Table: wishlist
-- ============================================================================
CREATE TABLE `wishlist` (
    `id` BIGINT AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `product_id` BIGINT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_wishlist_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_wishlist_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    
    -- Prevents the same user from adding the same product multiple times to their wishlist
    CONSTRAINT `uk_wishlist_user_product` UNIQUE (`user_id`, `product_id`),
    
    INDEX `idx_wishlist_user` (`user_id`),
    INDEX `idx_wishlist_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. Table: cart
-- ============================================================================
CREATE TABLE `cart` (
    `id` BIGINT AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_cart_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    
    -- Enforces a 1-to-1 relationship: A registered user can only have one active cart session
    CONSTRAINT `uk_cart_user` UNIQUE (`user_id`),
    
    INDEX `idx_cart_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. Table: cart_items
-- ============================================================================
CREATE TABLE `cart_items` (
    `id` BIGINT AUTO_INCREMENT,
    `cart_id` BIGINT NOT NULL,
    `product_id` BIGINT NOT NULL,
    `quantity` INT NOT NULL DEFAULT 1,
    
    -- Stores the price when the item was added, useful for price lock-in or audit purposes
    `price_at_added` DECIMAL(12, 2) NOT NULL,
    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_cart_items_cart` FOREIGN KEY (`cart_id`) REFERENCES `cart` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cart_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT,
    
    -- Ensures unique product lines within a cart (quantity is incremented instead of inserting new row)
    CONSTRAINT `uk_cart_items_cart_product` UNIQUE (`cart_id`, `product_id`),
    
    INDEX `idx_cart_items_cart` (`cart_id`),
    INDEX `idx_cart_items_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- Insert Seed Data (Example Records for testing)
-- ============================================================================

-- Seed skeleton users if not exists
INSERT INTO `users` (`id`, `username`, `email`) VALUES 
(1, 'roopa_mart', 'roopa@example.com'),
(2, 'john_guitar', 'john.doe@example.com')
ON DUPLICATE KEY UPDATE `username`=VALUES(`username`);

-- Seed skeleton products if not exists
INSERT INTO `products` (`id`, `name`, `sku`, `price`) VALUES 
(1, 'Fender Player Stratocaster Electric Guitar', 'FEN-PLY-STR-OW3', 849.99),
(2, 'Yamaha P-125 88-Key Weighted Digital Piano', 'YAM-P125B-88', 699.99)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- Seed Wishlist items
-- User 1 (roopa_mart) wishlists the Fender Stratocaster
INSERT INTO `wishlist` (`user_id`, `product_id`) VALUES (1, 1);
-- User 2 (john_guitar) wishlists the Yamaha Digital Piano
INSERT INTO `wishlist` (`user_id`, `product_id`) VALUES (2, 2);

-- Seed Cart sessions
-- User 1 (roopa_mart) has an active cart
INSERT INTO `cart` (`id`, `user_id`) VALUES (1, 1);
-- User 2 (john_guitar) has an active cart
INSERT INTO `cart` (`id`, `user_id`) VALUES (2, 2);

-- Seed Cart Items
-- User 1 has 1 Fender Stratocaster (Price locked at $849.99)
INSERT INTO `cart_items` (`cart_id`, `product_id`, `quantity`, `price_at_added`) 
VALUES (1, 1, 1, 849.99);

-- User 1 has 2 Yamaha Digital Pianos (Price locked at $699.99)
INSERT INTO `cart_items` (`cart_id`, `product_id`, `quantity`, `price_at_added`) 
VALUES (1, 2, 2, 699.99);
