-- ============================================================================
-- MelodyMart - Product Management Module Schema (MySQL 8)
-- Production-Ready Database Schema for E-commerce Product Catalog
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `melodymart_products` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `melodymart_products`;

-- Disable foreign key checks temporarily to drop tables in any order
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `product_specifications`;
DROP TABLE IF EXISTS `product_images`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `brands`;
DROP TABLE IF EXISTS `sub_categories`;
DROP TABLE IF EXISTS `categories`;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. Table: categories
-- ============================================================================
CREATE TABLE `categories` (
    `id` BIGINT AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `slug` VARCHAR(120) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `uk_categories_name` UNIQUE (`name`),
    CONSTRAINT `uk_categories_slug` UNIQUE (`slug`),
    
    INDEX `idx_categories_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. Table: sub_categories
-- ============================================================================
CREATE TABLE `sub_categories` (
    `id` BIGINT AUTO_INCREMENT,
    `category_id` BIGINT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `slug` VARCHAR(120) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_sub_categories_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `uk_sub_categories_category_name` UNIQUE (`category_id`, `name`),
    CONSTRAINT `uk_sub_categories_slug` UNIQUE (`slug`),
    
    INDEX `idx_sub_categories_category` (`category_id`),
    INDEX `idx_sub_categories_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. Table: brands
-- ============================================================================
CREATE TABLE `brands` (
    `id` BIGINT AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `slug` VARCHAR(120) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `logo_url` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `uk_brands_name` UNIQUE (`name`),
    CONSTRAINT `uk_brands_slug` UNIQUE (`slug`),
    
    INDEX `idx_brands_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. Table: products
-- ============================================================================
CREATE TABLE `products` (
    `id` BIGINT AUTO_INCREMENT,
    `name` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(180) NOT NULL,
    `brand_id` BIGINT NOT NULL,
    `category_id` BIGINT NOT NULL,
    `sub_category_id` BIGINT NOT NULL,
    `description` TEXT DEFAULT NULL,
    
    -- Currency pricing fields
    `price` DECIMAL(12, 2) NOT NULL,
    `discount_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    
    `stock_quantity` INT NOT NULL DEFAULT 0,
    `rating` DECIMAL(3, 2) NOT NULL DEFAULT 0.00,
    `review_count` INT NOT NULL DEFAULT 0,
    
    -- Warranty details (stored in months)
    `warranty_months` INT NOT NULL DEFAULT 0,
    
    `model_number` VARCHAR(100) DEFAULT NULL,
    `sku` VARCHAR(100) NOT NULL,
    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_products_brand` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_products_sub_category` FOREIGN KEY (`sub_category_id`) REFERENCES `sub_categories` (`id`) ON DELETE RESTRICT,
    
    CONSTRAINT `uk_products_slug` UNIQUE (`slug`),
    CONSTRAINT `uk_products_sku` UNIQUE (`sku`),

    -- Query optimization indexes
    INDEX `idx_products_slug` (`slug`),
    INDEX `idx_products_sku` (`sku`),
    INDEX `idx_products_brand` (`brand_id`),
    INDEX `idx_products_category` (`category_id`),
    INDEX `idx_products_sub_category` (`sub_category_id`),
    INDEX `idx_products_price` (`price`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. Table: product_images
-- ============================================================================
CREATE TABLE `product_images` (
    `id` BIGINT AUTO_INCREMENT,
    `product_id` BIGINT NOT NULL,
    `image_url` VARCHAR(512) NOT NULL,
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
    `display_order` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_product_images_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    
    INDEX `idx_product_images_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. Table: product_specifications
-- ============================================================================
CREATE TABLE `product_specifications` (
    `id` BIGINT AUTO_INCREMENT,
    `product_id` BIGINT NOT NULL,
    `spec_key` VARCHAR(100) NOT NULL,
    `spec_value` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_product_specifications_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `uk_product_specifications_key` UNIQUE (`product_id`, `spec_key`),
    
    INDEX `idx_product_specifications_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- INSERT SEED DATA
-- ============================================================================

-- 1. Populate categories
INSERT INTO `categories` (`id`, `name`, `slug`, `description`) VALUES
(1, 'String Instruments', 'string-instruments', 'Instruments containing strings that vibrate to produce sound (guitars, violins, cellos).'),
(2, 'Keyboard Instruments', 'keyboard-instruments', 'Instruments played using a musical keyboard interface (pianos, portable keys, stage keys).'),
(3, 'Percussion Instruments', 'percussion-instruments', 'Instruments struck to make rhythmic or melodic sounds (drum kits, tablas, cajons).'),
(4, 'Wind Instruments', 'wind-instruments', 'Instruments operated by blowing air into a resonator (flutes, trumpets, saxophones).'),

-- 2. Populate sub_categories
INSERT INTO `sub_categories` (`id`, `category_id`, `name`, `slug`, `description`) VALUES
-- String Instruments (Category 1)
(1, 1, 'Guitar', 'guitar', 'Acoustic, semi-acoustic, and electric guitars.'),
(2, 1, 'Violin', 'violin', 'Classical and electric violins.'),
(3, 1, 'Ukulele', 'ukulele', 'Four-string Hawaiian chordophones.'),
(4, 1, 'Bass Guitar', 'bass-guitar', 'Low-pitched electric or acoustic guitars.'),
(5, 1, 'Cello', 'cello', 'Large bowed orchestral string instruments.'),

-- Keyboard Instruments (Category 2)
(6, 2, 'Digital Piano', 'digital-piano', 'Electronic keyboard instruments designed to emulate acoustic pianos.'),
(7, 2, 'Grand Piano', 'grand-piano', 'Horizontal acoustic pianos with premium strings and action.'),
(8, 2, 'Upright Piano', 'upright-piano', 'Space-efficient vertical acoustic pianos.'),
(9, 2, 'Stage Piano', 'stage-piano', 'High-end performance keyboards for stage and studio.'),
(10, 2, 'Portable Keyboard', 'portable-keyboard', 'Lightweight keyboards with built-in speakers.'),
(11, 2, 'Arranger Keyboard', 'arranger-keyboard', 'Keyboards with automated backing accompaniment features.'),

-- Percussion Instruments (Category 3)
(12, 3, 'Drum Kit', 'drum-kit', 'Acoustic and electronic multi-drum sets.'),
(13, 3, 'Tabla', 'tabla', 'Traditional Indian twin hand-drums.'),
(14, 3, 'Conga', 'conga', 'Tall, narrow, single-headed African-Cuban drums.'),
(15, 3, 'Bongo', 'bongo', 'Small Afro-Cuban paired hand-drums.'),
(16, 3, 'Cajon', 'cajon', 'Box-shaped percussion instruments originating from Peru.'),

-- Wind Instruments (Category 4)
(17, 4, 'Flute', 'flute', 'Woodwind instruments producing sound from flow of air.'),
(18, 4, 'Trumpet', 'trumpet', 'High-register brass instruments with three valves.'),
(19, 4, 'Clarinet', 'clarinet', 'Single-reed woodwind instruments with cylindrical bores.'),
(20, 4, 'Saxophone', 'saxophone', 'Single-reed brass woodwind instruments used widely in jazz.'),
(21, 4, 'Harmonica', 'harmonica', 'Free-reed pocket wind instruments.');

-- Electronic Instruments (Category 5)

-- 3. Populate brands
INSERT INTO `brands` (`id`, `name`, `slug`, `description`, `logo_url`) VALUES
(1, 'Yamaha', 'yamaha', 'Global leader in musical instrument production and digital audio systems.', 'https://cdn.melodymart.com/brands/yamaha.png'),
(2, 'Fender', 'fender', 'Legendary manufacturer of acoustic, electric, and bass guitars.', 'https://cdn.melodymart.com/brands/fender.png'),
(3, 'Roland', 'roland', 'Pioneering electronic instruments manufacturer, synthesizer developer, and digital drums producer.', 'https://cdn.melodymart.com/brands/roland.png'),
(4, 'Shure', 'shure', 'Industry-standard microphones and studio audio monitoring gear.', 'https://cdn.melodymart.com/brands/shure.png'),
(5, 'Focusrite', 'focusrite', 'Renowned manufacturer of high-quality USB audio recording interfaces.', 'https://cdn.melodymart.com/brands/focusrite.png');

-- 4. Populate products
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (1, 'Fender Player Stratocaster Electric Guitar', 'fender-player-stratocaster-electric-guitar', 2, 1, 1, 'The inspiring sound of a Stratocaster is one of the foundations of Fender. Featuring this classic sound—bell-like high end, punchy mids and robust low end, combined with crystal-clear articulation—the Player Stratocaster is packed with authentic Fender feel and style.', 849.99, 10, 25, 4.82, 142, 24, '0144502513', 'FEN-PLY-STR-OW3');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (6, 'Fender Paramount PM-1 Dreadnought Acoustic Guitar', 'fender-paramount-pm1-acoustic', 2, 1, 1, 'An expansion of the Paramount Series, the PM-1 Standard Dreadnought combines simple styling with an organic finish to create a highly responsive acoustic guitar. Crafted with premium solid tone woods including mahogany back and sides and a solid Sitka spruce top.', 799, 0, 14, 4.65, 38, 12, 'PM-1-STD', 'FEN-PAR-PM1-NAT');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (7, 'Yamaha C40 II Classical Nylon Guitar', 'yamaha-c40-ii-classical-guitar', 1, 1, 1, 'The Yamaha C40 II classical guitar is an outstanding full-size nylon-string instrument that is affordable enough for any beginner, yet delivers a clean tone and excellent playability suitable for advanced guitarists.', 159.99, 5, 80, 4.72, 650, 24, 'C40II', 'YAM-C40II-CL');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (8, 'Yamaha FG800 Solid Top Acoustic Guitar', 'yamaha-fg800-acoustic-guitar', 1, 1, 1, 'Yamaha''s standard acoustic model, with simple and traditional looks and outstanding quality, at an affordable price. A solid-top guitar with authentic sound that is well balanced without losing its robust strength.', 229.99, 0, 45, 4.8, 421, 24, 'FG800', 'YAM-FG800-NT');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (9, 'Yamaha SV-250 Silent Violin', 'yamaha-sv-250-silent-violin', 1, 1, 2, 'Designed to meet the needs of the professional performer playing diverse genres. An acoustic body hollow chamber design provides an extremely natural violin sound, while the dual pickup system offers high-end signal output control.', 1799, 8, 8, 4.88, 19, 36, 'SV-250', 'YAM-SV250-BR');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (10, 'Fender Concert Tone 54 Mandolin', 'fender-concert-tone-54-mandolin', 2, 1, 3, 'The Concert Tone 54 Mandolin delivers the traditional bright, ringing tone of an ''A''-style mandolin. Features a spruce top with ''F'' holes, mahogany back and sides, and clean classic appointments.', 299.99, 10, 12, 4.54, 22, 12, 'CT-54', 'FEN-CT54-MND');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (11, 'Fender Seaside Soprano Ukulele', 'fender-seaside-soprano-ukulele', 2, 1, 3, 'Crafted from mahogany for a warm, bell-like tone, the Seaside Ukulele is compact, comfortable, and easy to pack for beach trips or studio sessions. A satin finish gives it an organic look and feel.', 89.99, 0, 95, 4.7, 114, 12, 'SEASIDE-SOP', 'FEN-SEA-SOP-UK');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (12, 'Yamaha TRBX304 Active Bass Guitar', 'yamaha-trbx304-bass-guitar', 1, 1, 4, 'TRBX300 is built around a simple principle - your performance. The perfectly balanced, ultra-comfortable solid mahogany body provides the optimum tonal foundation, while active EQ circuitry gives you instant tone customization.', 399.99, 0, 18, 4.76, 88, 24, 'TRBX304', 'YAM-TRBX304-CAR');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (13, 'Fender Mustang Bass PJ', 'fender-mustang-bass-pj', 2, 1, 4, 'Since its release in 1964, the Mustang Bass has been one of Fender''s most enduring designs. This upgraded short-scale version adds the power of legendary P Bass and J Bass pickups to the traditional Mustang body.', 679.99, 5, 10, 4.81, 54, 24, 'MUSTANG-PJ', 'FEN-MST-PJ-BS');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (14, 'Yamaha SVC-110 Silent Cello', 'yamaha-svc-110-silent-cello', 1, 1, 5, 'The SVC-110 was created in cooperation with some of the world''s greatest cellists. It features a unique acoustic chamber that gives cellists a warm, natural playing response in a highly portable package.', 2499.99, 10, 4, 4.93, 15, 36, 'SVC-110', 'YAM-SVC110-CEL');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (2, 'Yamaha P-125 88-Key Weighted Digital Piano', 'yamaha-p-125-weighted-digital-piano', 1, 2, 6, 'The Yamaha P-125 is a compact digital piano that combines incredible piano performance with a user-friendly minimalist design. Easily portable and extremely accessible, this instrument allows you to experience the joy of playing the piano on your terms.', 699.99, 0, 40, 4.75, 98, 36, 'P125B', 'YAM-P125B-88');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (15, 'Roland FP-30X Portable Digital Piano', 'roland-fp-30x-digital-piano', 3, 2, 6, 'When quality matters but budget is a factor, the FP-30X is the sweet spot of Roland''s FP-X series. Balancing its entry-level price with professional performance, this slim and stylish portable piano features Roland''s SuperNATURAL sound engine.', 749.99, 5, 30, 4.81, 112, 24, 'FP-30X', 'ROL-FP30X-BK');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (16, 'Roland GP-6 Premium Digital Grand Piano', 'roland-gp6-digital-grand-piano', 3, 2, 7, 'The GP-6 is a mid-level grand piano that offers a baby grand look with Roland''s latest sound engine technologies. Featuring elegant curves, detailed acoustic emulation, and a premium multi-channel speaker array.', 5499, 0, 3, 4.96, 8, 60, 'GP-6-PE', 'ROL-GP6-GRAND');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (17, 'Yamaha B3 Premium Upright Acoustic Piano', 'yamaha-b3-upright-piano', 1, 2, 8, 'The introduction of the Yamaha b3 to the b-series range approaches professional standards while remaining true to the b-series design philosophy of value and affordability. Solid spruce soundboard delivers rich, resonant tone.', 4899, 0, 2, 4.9, 14, 120, 'b3-PE', 'YAM-B3-UPRIGHT');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (18, 'Roland RD-2000 Professional Stage Piano', 'roland-rd-2000-stage-piano', 3, 2, 9, 'Equipped with dual independent sound engines, premium action, and advanced controller features, the Roland RD-2000 delivers unmatched performance on stage and in the studio. A gold standard for performing keyboardists.', 2599.99, 5, 8, 4.87, 42, 36, 'RD-2000', 'ROL-RD2000-SP');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (19, 'Yamaha PSR-E373 61-Key Portable Keyboard', 'yamaha-psr-e373-portable-keyboard', 1, 2, 10, 'Features a touch-sensitive keyboard and an all-new tone generator LSI that delivers a comprehensive library of 622 high-quality instrument Voices, perfect for learning, practice, or performing.', 199.99, 0, 75, 4.68, 312, 24, 'PSR-E373', 'YAM-PSRE373-KB');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (20, 'Roland GO:KEYS 61-Key Music Creation Keyboard', 'roland-gokeys-61-keyboard', 3, 2, 10, 'An innovative, fun keyboard that lets you play along with your favorite music streamed from your smartphone. Simply connect via Bluetooth, choose a song, and start jamming!', 329.99, 10, 34, 4.62, 56, 24, 'GO-61K', 'ROL-GO61K-KB');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (21, 'Yamaha PSR-SX900 Professional Arranger Workstation', 'yamaha-psrsx900-arranger', 1, 2, 11, 'Take your performance to a whole new level with the PSR-SX900. Replacing the legendary PSR-S series, this workstation features a redesigned sound system, touch screen interface, and assignable controller functions.', 2199, 0, 6, 4.92, 28, 36, 'PSR-SX900', 'YAM-SX900-ARR');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (22, 'Roland E-X50 Arranger Keyboard', 'roland-ex50-arranger', 3, 2, 11, 'With its sleek design, professional Roland sounds, and integrated speaker system, the E-X50 Arranger Keyboard puts musical inspiration at the center of your practice and performance.', 399.99, 5, 18, 4.7, 17, 24, 'E-X50', 'ROL-EX50-ARR');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (23, 'Roland Fantom-08 Music Workstation Synthesizer', 'roland-fantom08-workstation', 3, 2, 9, 'FANTOM-08 brings your creative world together, combining the sonic power and fluid workflow of the top-of-the-line FANTOM series in streamlined instruments with weighted 88-key action.', 1999.99, 0, 5, 4.89, 22, 24, 'FANTOM-08', 'ROL-FAN08-WS');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (3, 'Roland TD-17KVX V-Drums Electronic Drum Kit', 'roland-td-17kvx-electronic-drum-kit', 3, 3, 12, 'The Roland TD-17KVX allows your technique to shine through, backed up with training tools to push you further. Combining a TD-50-class sound engine with newly developed pads results in an affordable electronic drum kit.', 1499.99, 5, 15, 4.88, 64, 12, 'TD-17KVX', 'ROL-TD17KVX-DK');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (24, 'Yamaha Stage Custom Birch Acoustic Drum Kit', 'yamaha-stage-custom-birch-acoustic', 1, 3, 12, 'As with the introduction of Stage Custom in 1995, YAMAHA once again sets the value standard for acoustic drums. A 100% birch shell kit complete with hardware packs, suitable for stage setups.', 679.99, 0, 10, 4.84, 45, 24, 'SBP2F50', 'YAM-SCB-BIRCH');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (25, 'Yamaha Rydeen 5-Piece Entry Drum Kit', 'yamaha-rydeen-drumkit', 1, 3, 12, 'The new RYDEEN (5-piece shell pack) is exactly what any beginner or intermediate player would love to play. Features double-brace hardware legs and genuine Yamaha tom clamps.', 499.99, 8, 20, 4.68, 89, 24, 'RYDEEN-5PC', 'YAM-RYD-5PC-RD');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (26, 'Roland TD-07DMK V-Drums Entry Electronic Kit', 'roland-td07dmk-electronic-drums', 3, 3, 12, 'Compact and priced ideally for home practice, the TD-07DMK is the entry point to the V-Drums TD-07 series, offering premium pads, quiet operation, and deep editing control.', 799.99, 0, 25, 4.7, 37, 12, 'TD-07DMK', 'ROL-TD07DMK-ED');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (27, 'Yamaha Premium Wood Conga Pair', 'yamaha-premium-wood-congas', 1, 3, 14, 'Traditional Cuban-style conga drums crafted with aged Siam Oak wood shells to deliver clean highs, punchy mid-tones, and robust bass slaps. Set includes a double-braced height-adjustable stand.', 449.99, 10, 8, 4.73, 16, 24, 'YCG-1112', 'YAM-WCG-PAIR');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (28, 'Roland SPD-SX PRO flagship Sampling Pad', 'roland-spdsx-pro-sampler', 3, 3, 12, 'The SPD-SX PRO is the ultimate sampling pad for the most demanding gigs. With years of feedback from touring drummers, it features customizable LED lights, large screens, and inputs.', 1199.99, 0, 12, 4.94, 48, 24, 'SPD-SX-PRO', 'ROL-SPDSXP-SP');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (29, 'Yamaha Double-Headed Indian Tabla Set', 'yamaha-indian-tabla-set', 1, 3, 13, 'Handcrafted traditional Indian twin hand-drums. Features a heavy chrome-plated brass Bayan (bass drum) and an aged seasoned Sheesham wood Dayan (treble drum). Tuning hammers included.', 249.99, 5, 15, 4.78, 30, 12, 'TAB-YAM', 'YAM-TABLA-SET');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (30, 'Roland HandSonic HPD-20 Digital Hand Percussion', 'roland-handsonic-hpd20', 3, 3, 12, 'Roland takes digital hand percussion to a new level with the HandSonic HPD-20, a unique instrument ideal for hand percussionists, beatmakers, and electronic composers.', 999.99, 0, 6, 4.81, 23, 24, 'HPD-20', 'ROL-HPD20-HP');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (31, 'Yamaha Snare Cajon Wood Box', 'yamaha-snare-cajon-box', 1, 3, 16, 'Standard Peruvian-style Cajon box constructed with natural Meranti wood and integrated internal snare wires, delivering crisp snare rolls and punchy, low-end bass thuds.', 129.99, 10, 40, 4.6, 52, 12, 'CJ-YAM', 'YAM-SNARE-CAJ');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (32, 'Roland El Cajon Hybrid Box EC-10', 'roland-el-cajon-ec10', 3, 3, 16, 'The EC-10 El Cajon allows acoustic cajon players to easily blend their organic sounds with electronic layers, utilizing built-in trigger sensors and Roland''s sound module technology.', 399.99, 0, 11, 4.74, 18, 24, 'EC-10', 'ROL-EC10-CAJ');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (33, 'Yamaha YFL-222 Student Flute', 'yamaha-yfl-222-flute', 1, 4, 17, 'Designed for beginners, the YFL-222 features closed-hole keys and offset G configuration, making it the industry standard for student flute playability, tone, and long-term durability.', 549, 5, 30, 4.79, 84, 24, 'YFL-222', 'YAM-YFL222-FL');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (34, 'Yamaha YTR-2330 Student Bb Trumpet', 'yamaha-ytr-2330-trumpet', 1, 4, 18, 'The two-piece bell of the YTR-2330 is crafted using state-of-the-art manufacturing methods, delivering a consistent, vibrant tone. The balanced weight and addition of an adjustable third valve trigger allow for natural hand positioning.', 699, 0, 15, 4.82, 41, 24, 'YTR-2330', 'YAM-YTR2330-TR');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (35, 'Yamaha YCL-250 Student Bb Clarinet', 'yamaha-ycl-250-clarinet', 1, 4, 19, 'A Bb clarinet constructed with durable matte ABS resin, designed to emulate the warm appearance and acoustic properties of traditional Grenadilla wood models, but resistant to environmental cracking.', 589, 0, 22, 4.71, 63, 24, 'YCL-250', 'YAM-YCL250-CL');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (36, 'Yamaha YAS-280 Student Alto Saxophone', 'yamaha-yas-280-saxophone', 1, 4, 20, 'The YAS-280 saxophones offer a perfect start because they are designed with the young beginner in mind. Relatively lightweight and ergonomically shaped, they are easy to hold and play.', 1249, 5, 12, 4.88, 76, 24, 'YAS-280', 'YAM-YAS280-SAX');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (37, 'Fender Blues Deluxe Bb Harmonica', 'fender-blues-deluxe-harmonica', 2, 4, 21, 'Perfect for the seasoned harpist or those just starting out, the Fender Blues Deluxe harmonica is versatile enough for any level of player. Features solid construction, comfortable shape, and bright tone.', 19.99, 0, 200, 4.64, 450, 12, 'BLUES-DELUXE', 'FEN-BLU-DLX-BB');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (38, 'Yamaha YFL-372 Intermediate Flute', 'yamaha-yfl-372-flute', 1, 4, 17, 'An upgrade model featuring a solid sterling silver headjoint to produce a richer, warmer tone with greater projection. Open-hole key design encourages proper hand placement.', 1149, 10, 8, 4.86, 29, 24, 'YFL-372', 'YAM-YFL372-FL');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (39, 'Yamaha YTR-4335GSII Intermediate Trumpet', 'yamaha-ytr4335-trumpet', 1, 4, 18, 'Features a gold-brass bell that produces a richer, wider range of tonal colors. Monel alloy pistons and a modified bell design ensure quick, smooth valve response.', 1399, 0, 6, 4.8, 18, 24, 'YTR-4335GSII', 'YAM-YTR4335-TR');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (40, 'Yamaha YCL-450 Intermediate Wood Clarinet', 'yamaha-ycl-450-wood-clarinet', 1, 4, 19, 'Crafted from select Grenadilla wood body, the YCL-450 delivers a warm, rich tone that begins to approach the sound of Yamaha''s professional clarinet models.', 1299, 0, 9, 4.91, 33, 36, 'YCL-450', 'YAM-YCL450-CL');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (41, 'Yamaha YAS-480 Intermediate Alto Saxophone', 'yamaha-yas480-saxophone', 1, 4, 20, 'The YAS-480 saxophones are a step ahead. With a little bit more resistance, they have an authoritative sound yet great flexibility due to the separate key guards.', 2199, 5, 4, 4.9, 22, 24, 'YAS-480', 'YAM-YAS480-SAX');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (42, 'Fender Midnight Special Diatonic Harmonica', 'fender-midnight-special-harmonica', 2, 4, 21, 'A premium diatonic harmonica featuring a precision-molded ABS comb and solid brass reeds inside a sleek, matte black stainless steel cover. Tuned to Key of C.', 39.99, 10, 100, 4.7, 142, 12, 'MIDNIGHT-SPECIAL', 'FEN-MID-SPL-C');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (101, 'Yamaha Premium Fiddle', 'yamaha-premium-fiddle', 1, 1, 2, 'The Yamaha Premium Fiddle is a meticulously designed Fiddle crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 778.31, 10, 11, 4.69, 27, 24, 'FID-242', 'MEL-STR-FID-101');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (102, 'Fender Premium Lute', 'fender-premium-lute', 2, 1, 5, 'The Fender Premium Lute is a meticulously designed Lute crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 274.99, 0, 8, 4.85, 60, 12, 'LUT-758', 'MEL-STR-LUT-102');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (103, 'Fender Premium Oud', 'fender-premium-oud', 2, 1, 5, 'The Fender Premium Oud is a meticulously designed Oud crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 393.34, 0, 23, 4.93, 68, 24, 'OUD-674', 'MEL-STR-OUD-103');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (104, 'Fender Premium Erhu', 'fender-premium-erhu', 2, 1, 2, 'The Fender Premium Erhu is a meticulously designed Erhu crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 300.89, 0, 5, 4.91, 65, 12, 'ERH-889', 'MEL-STR-ERH-104');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (105, 'Yamaha Premium Santoor', 'yamaha-premium-santoor', 1, 1, 5, 'The Yamaha Premium Santoor is a meticulously designed Santoor crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 804.52, 10, 23, 4.72, 38, 12, 'SAN-689', 'MEL-STR-SAN-105');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (106, 'Fender Premium Tanpura', 'fender-premium-tanpura', 2, 1, 5, 'The Fender Premium Tanpura is a meticulously designed Tanpura crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 431.06, 0, 5, 4.9, 15, 12, 'TAN-628', 'MEL-STR-TAN-106');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (107, 'Yamaha Premium Veena', 'yamaha-premium-veena', 1, 1, 5, 'The Yamaha Premium Veena is a meticulously designed Veena crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 433.07, 0, 12, 4.54, 19, 12, 'VEE-889', 'MEL-STR-VEE-107');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (108, 'Fender Premium Sarod', 'fender-premium-sarod', 2, 1, 5, 'The Fender Premium Sarod is a meticulously designed Sarod crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 716.51, 0, 14, 4.73, 42, 24, 'SAR-655', 'MEL-STR-SAR-108');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (109, 'Yamaha Premium sitar', 'yamaha-premium-sitar', 1, 1, 5, 'The Yamaha Premium sitar is a meticulously designed sitar crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 115.76, 5, 23, 4.86, 34, 12, 'SIT-473', 'MEL-STR-SIT-109');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (110, 'Fender Premium Banjo', 'fender-premium-banjo', 2, 1, 3, 'The Fender Premium Banjo is a meticulously designed Banjo crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 848.7, 10, 7, 4.7, 79, 24, 'BAN-236', 'MEL-STR-BAN-110');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (111, 'Yamaha Premium Toy Piano', 'yamaha-premium-toy-piano', 1, 2, 10, 'The Yamaha Premium Toy Piano is a meticulously designed Toy Piano crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 378.41, 5, 13, 4.54, 31, 12, 'TOY-239', 'MEL-KEY-TOY-111');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (112, 'Yamaha Premium Spinet Piano', 'yamaha-premium-spinet-piano', 1, 2, 8, 'The Yamaha Premium Spinet Piano is a meticulously designed Spinet Piano crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 191.35, 5, 17, 4.61, 24, 24, 'SPI-718', 'MEL-KEY-SPI-112');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (113, 'Roland Premium concert Organ', 'roland-premium-concert-organ', 3, 2, 10, 'The Roland Premium concert Organ is a meticulously designed concert Organ crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 330.66, 10, 17, 4.83, 58, 24, 'CON-264', 'MEL-KEY-CON-113');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (114, 'Roland Premium Electric Keyboard', 'roland-premium-electric-keyboard', 3, 2, 10, 'The Roland Premium Electric Keyboard is a meticulously designed Electric Keyboard crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 858.14, 10, 7, 4.81, 85, 24, 'ELE-811', 'MEL-KEY-ELE-114');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (115, 'Roland Premium Melodica', 'roland-premium-melodica', 3, 2, 10, 'The Roland Premium Melodica is a meticulously designed Melodica crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 872.77, 5, 14, 4.69, 45, 24, 'MEL-594', 'MEL-KEY-MEL-115');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (116, 'Roland Premium MIDI keyboard controller', 'roland-premium-midi-keyboard-controller', 3, 2, 10, 'The Roland Premium MIDI keyboard controller is a meticulously designed MIDI keyboard controller crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 197.86, 10, 24, 4.53, 19, 12, 'MID-388', 'MEL-KEY-MID-116');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (117, 'Roland Premium Celesta', 'roland-premium-celesta', 3, 2, 10, 'The Roland Premium Celesta is a meticulously designed Celesta crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 99.26, 10, 11, 4.63, 29, 24, 'CEL-315', 'MEL-KEY-CEL-117');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (118, 'Roland Premium Clavichord', 'roland-premium-clavichord', 3, 2, 10, 'The Roland Premium Clavichord is a meticulously designed Clavichord crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 200.9, 5, 6, 4.86, 26, 24, 'CLA-872', 'MEL-KEY-CLA-118');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (119, 'Roland Premium Harpsichord', 'roland-premium-harpsichord', 3, 2, 10, 'The Roland Premium Harpsichord is a meticulously designed Harpsichord crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 406.81, 0, 9, 4.72, 64, 12, 'HAR-489', 'MEL-KEY-HAR-119');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (120, 'Roland Premium Accordion', 'roland-premium-accordion', 3, 2, 10, 'The Roland Premium Accordion is a meticulously designed Accordion crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 370.45, 0, 16, 4.53, 84, 24, 'ACC-314', 'MEL-KEY-ACC-120');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (121, 'Roland Premium Timpani(kettle Drum)', 'roland-premium-timpani-kettle-drum', 3, 3, 12, 'The Roland Premium Timpani(kettle Drum) is a meticulously designed Timpani(kettle Drum) crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 123.31, 0, 13, 4.57, 34, 24, 'TIM-695', 'MEL-PER-TIM-121');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (122, 'Roland Premium Vibraphone', 'roland-premium-vibraphone', 3, 3, 12, 'The Roland Premium Vibraphone is a meticulously designed Vibraphone crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 494.56, 5, 12, 4.72, 10, 12, 'VIB-359', 'MEL-PER-VIB-122');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (123, 'Roland Premium Marimba', 'roland-premium-marimba', 3, 3, 12, 'The Roland Premium Marimba is a meticulously designed Marimba crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 736.31, 0, 9, 4.66, 24, 12, 'MAR-199', 'MEL-PER-MAR-123');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (124, 'Roland Premium Xylophone', 'roland-premium-xylophone', 3, 3, 12, 'The Roland Premium Xylophone is a meticulously designed Xylophone crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 804.12, 0, 25, 4.51, 31, 24, 'XYL-690', 'MEL-PER-XYL-124');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (125, 'Roland Premium Cowbell', 'roland-premium-cowbell', 3, 3, 12, 'The Roland Premium Cowbell is a meticulously designed Cowbell crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 341.3, 0, 16, 4.87, 43, 12, 'COW-863', 'MEL-PER-COW-125');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (126, 'Roland Premium Claves', 'roland-premium-claves', 3, 3, 12, 'The Roland Premium Claves is a meticulously designed Claves crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 472.49, 0, 27, 4.91, 68, 24, 'CLA-204', 'MEL-PER-CLA-126');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (127, 'Roland Premium Castanet', 'roland-premium-castanet', 3, 3, 12, 'The Roland Premium Castanet is a meticulously designed Castanet crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 121.24, 0, 17, 4.9, 44, 24, 'CAS-168', 'MEL-PER-CAS-127');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (128, 'Roland Premium Maracas', 'roland-premium-maracas', 3, 3, 12, 'The Roland Premium Maracas is a meticulously designed Maracas crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 884.15, 0, 19, 4.72, 31, 24, 'MAR-524', 'MEL-PER-MAR-128');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (129, 'Roland Premium Triangle', 'roland-premium-triangle', 3, 3, 12, 'The Roland Premium Triangle is a meticulously designed Triangle crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 313.95, 5, 16, 4.9, 44, 24, 'TRI-577', 'MEL-PER-TRI-129');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (130, 'Roland Premium Tambourine', 'roland-premium-tambourine', 3, 3, 12, 'The Roland Premium Tambourine is a meticulously designed Tambourine crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 297.8, 5, 6, 4.95, 30, 12, 'TAM-198', 'MEL-PER-TAM-130');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (131, 'Yamaha Premium Basson', 'yamaha-premium-basson', 1, 4, 21, 'The Yamaha Premium Basson is a meticulously designed Basson crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 276.21, 10, 26, 4.82, 54, 12, 'BAS-138', 'MEL-WIN-BAS-131');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (132, 'Yamaha Premium Recorder', 'yamaha-premium-recorder', 1, 4, 17, 'The Yamaha Premium Recorder is a meticulously designed Recorder crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 574.25, 0, 25, 4.87, 83, 12, 'REC-122', 'MEL-WIN-REC-132');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (133, 'Yamaha Premium Trombone', 'yamaha-premium-trombone', 1, 4, 18, 'The Yamaha Premium Trombone is a meticulously designed Trombone crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 231.25, 10, 28, 4.52, 28, 24, 'TRO-390', 'MEL-WIN-TRO-133');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (134, 'Yamaha Premium Pan Flute', 'yamaha-premium-pan-flute', 1, 4, 17, 'The Yamaha Premium Pan Flute is a meticulously designed Pan Flute crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 829.69, 5, 27, 4.65, 19, 24, 'PAN-999', 'MEL-WIN-PAN-134');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (135, 'Yamaha Premium Bugle', 'yamaha-premium-bugle', 1, 4, 18, 'The Yamaha Premium Bugle is a meticulously designed Bugle crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 717.57, 5, 9, 4.89, 60, 12, 'BUG-175', 'MEL-WIN-BUG-135');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (136, 'Yamaha Premium euphonium', 'yamaha-premium-euphonium', 1, 4, 18, 'The Yamaha Premium euphonium is a meticulously designed euphonium crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 184.15, 10, 23, 4.57, 71, 24, 'EUP-219', 'MEL-WIN-EUP-136');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (137, 'Yamaha Premium French Horn', 'yamaha-premium-french-horn', 1, 4, 18, 'The Yamaha Premium French Horn is a meticulously designed French Horn crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 114.12, 0, 16, 4.84, 32, 24, 'FRE-523', 'MEL-WIN-FRE-137');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (138, 'Yamaha Premium Tuba', 'yamaha-premium-tuba', 1, 4, 18, 'The Yamaha Premium Tuba is a meticulously designed Tuba crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 563.95, 10, 29, 4.56, 19, 24, 'TUB-687', 'MEL-WIN-TUB-138');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (139, 'Yamaha Premium English Horn (Cor Anglais)', 'yamaha-premium-english-horn-cor-anglais', 1, 4, 21, 'The Yamaha Premium English Horn (Cor Anglais) is a meticulously designed English Horn (Cor Anglais) crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 853.9, 5, 29, 4.5, 74, 24, 'ENG-109', 'MEL-WIN-ENG-139');
INSERT INTO `products` (`id`, `name`, `slug`, `brand_id`, `category_id`, `sub_category_id`, `description`, `price`, `discount_percentage`, `stock_quantity`, `rating`, `review_count`, `warranty_months`, `model_number`, `sku`) VALUES (140, 'Yamaha Premium Cornet', 'yamaha-premium-cornet', 1, 4, 18, 'The Yamaha Premium Cornet is a meticulously designed Cornet crafted for outstanding acoustic clarity and robust build. Ideal for both studio recordings and live performance sets, it features high-quality premium fittings.', 367.82, 0, 20, 4.71, 56, 12, 'COR-392', 'MEL-WIN-COR-140');

-- 5. Populate product_images
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (1, 'https://ik.imagekit.io/kmox85pel/Electric%20Guitar.avif', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (6, 'https://ik.imagekit.io/kmox85pel/Acoustic%20Guitar.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (7, 'https://ik.imagekit.io/kmox85pel/Classical%20Guitar.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (8, 'https://ik.imagekit.io/kmox85pel/Acoustic%20Guitar.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (9, 'https://ik.imagekit.io/kmox85pel/violin.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (10, 'https://ik.imagekit.io/kmox85pel/Mandolin.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (11, 'https://ik.imagekit.io/kmox85pel/Ukulele.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (12, 'https://ik.imagekit.io/kmox85pel/double-bass.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (13, 'https://ik.imagekit.io/kmox85pel/double-bass.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (14, 'https://ik.imagekit.io/kmox85pel/Cello.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (2, 'https://ik.imagekit.io/kmox85pel/Digital%20Piano.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (15, 'https://ik.imagekit.io/kmox85pel/Digital%20Piano.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (16, 'https://ik.imagekit.io/kmox85pel/Grand%20Piano.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (17, 'https://ik.imagekit.io/kmox85pel/Upright%20Piano.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (18, 'https://ik.imagekit.io/kmox85pel/Stage%20Piano.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (19, 'https://ik.imagekit.io/kmox85pel/Portable%20Keyboard.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (20, 'https://ik.imagekit.io/kmox85pel/Electronic%20Keyboard.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (21, 'https://ik.imagekit.io/kmox85pel/Arranger%20Keyboard.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (22, 'https://ik.imagekit.io/kmox85pel/Arranger%20Keyboard.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (23, 'https://ik.imagekit.io/kmox85pel/Synthesizer.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (3, 'https://ik.imagekit.io/kmox85pel/drum%20set.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (24, 'https://ik.imagekit.io/kmox85pel/drum%20set.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (25, 'https://ik.imagekit.io/kmox85pel/drum%20set.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (26, 'https://ik.imagekit.io/kmox85pel/drum%20set.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (27, 'https://ik.imagekit.io/kmox85pel/congo%20drum.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (28, 'https://ik.imagekit.io/kmox85pel/drum%20set.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (29, 'https://ik.imagekit.io/kmox85pel/Tabla.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (30, 'https://ik.imagekit.io/kmox85pel/drum%20set.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (31, 'https://ik.imagekit.io/kmox85pel/cajon.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (32, 'https://ik.imagekit.io/kmox85pel/cajon.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (33, 'https://ik.imagekit.io/kmox85pel/wind%20wood/flute.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (34, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Trumpet.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (35, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Clarinet.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (36, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Saxophone.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (37, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Harmonica.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (38, 'https://ik.imagekit.io/kmox85pel/wind%20wood/flute.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (39, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Trumpet.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (40, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Clarinet.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (41, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Saxophone.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (42, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Harmonica.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (101, 'https://ik.imagekit.io/kmox85pel/Fiddle%20(a%20violin%20used%20in%20folk%20music).webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (102, 'https://ik.imagekit.io/kmox85pel/Lute.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (103, 'https://ik.imagekit.io/kmox85pel/Oud.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (104, 'https://ik.imagekit.io/kmox85pel/Erhu.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (105, 'https://ik.imagekit.io/kmox85pel/Santoor.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (106, 'https://ik.imagekit.io/kmox85pel/Tanpura.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (107, 'https://ik.imagekit.io/kmox85pel/Veena.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (108, 'https://ik.imagekit.io/kmox85pel/Sarod.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (109, 'https://ik.imagekit.io/kmox85pel/sitar.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (110, 'https://ik.imagekit.io/kmox85pel/Banjo.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (111, 'https://ik.imagekit.io/kmox85pel/Toy%20Piano.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (112, 'https://ik.imagekit.io/kmox85pel/Spinet%20Piano.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (113, 'https://ik.imagekit.io/kmox85pel/Concert%20Organ.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (114, 'https://ik.imagekit.io/kmox85pel/Electric%20Piano%20(Rhodes).jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (115, 'https://ik.imagekit.io/kmox85pel/Melodica.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (116, 'https://ik.imagekit.io/kmox85pel/MIDI%20Keyboard%20Controller.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (117, 'https://ik.imagekit.io/kmox85pel/Celesta.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (118, 'https://ik.imagekit.io/kmox85pel/Clavichord.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (119, 'https://ik.imagekit.io/kmox85pel/Harpsichord.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (120, 'https://ik.imagekit.io/kmox85pel/accordion.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (121, 'https://ik.imagekit.io/kmox85pel/Timpani(kettle%20drum).jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (122, 'https://ik.imagekit.io/kmox85pel/Vibraphone.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (123, 'https://ik.imagekit.io/kmox85pel/Marimba.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (124, 'https://ik.imagekit.io/kmox85pel/Xylophone.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (125, 'https://ik.imagekit.io/kmox85pel/Cowbell.avif', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (126, 'https://ik.imagekit.io/kmox85pel/Claves.webp', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (127, 'https://ik.imagekit.io/kmox85pel/Castanet.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (128, 'https://ik.imagekit.io/kmox85pel/Maracas.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (129, 'https://ik.imagekit.io/kmox85pel/Triangle.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (130, 'https://ik.imagekit.io/kmox85pel/Tambourine.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (131, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Bassoon.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (132, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Recorder.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (133, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Trombone.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (134, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Pan%20Flute.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (135, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Bugle.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (136, 'https://ik.imagekit.io/kmox85pel/wind%20wood/eupho.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (137, 'https://ik.imagekit.io/kmox85pel/wind%20wood/French%20Horn.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (138, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Tuba.jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (139, 'https://ik.imagekit.io/kmox85pel/wind%20wood/English%20Horn%20(Cor%20Anglais).jpeg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image_url`, `is_primary`, `display_order`) VALUES (140, 'https://ik.imagekit.io/kmox85pel/wind%20wood/Cornet.jpeg', 1, 1);

-- 6. Populate product_specifications
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (1, 'Body Material', 'Alder');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (1, 'Neck Material', 'Maple');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (1, 'Scale Length', '25.5 in');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (1, 'Number of Frets', '22');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (1, 'Color', 'Olympic White');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (6, 'Body Type', 'Dreadnought');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (6, 'Top Wood', 'Solid Sitka Spruce');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (6, 'Back & Sides', 'Solid Mahogany');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (6, 'Finish', 'Open-Pore Satin');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (7, 'String Type', 'Nylon');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (7, 'Top Wood', 'Spruce');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (7, 'Fretboard Material', 'Rosewood');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (7, 'Scale Length', '25.56 in');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (8, 'Top Wood', 'Solid Spruce');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (8, 'Back & Sides', 'Nato/Okume');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (8, 'Body Shape', 'Traditional Western');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (9, 'Body', 'Spruce/Maple');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (9, 'Pickup System', 'Piezo Dual pickup (Bridge & Body)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (9, 'Weight', '1.1 lbs');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (10, 'Body Style', 'A-Style');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (10, 'Top Wood', 'Spruce');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (10, 'Back & Sides', 'Mahogany');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (11, 'Size', 'Soprano');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (11, 'Body Material', 'Mahogany');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (11, 'Number of Frets', '16');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (12, 'Body Material', 'Solid Mahogany');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (12, 'Neck Material', '5-piece Maple/Mahogany');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (12, 'Pickups', 'Double Hum-cancelling Ceramic Pickups');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (12, 'Active Electronics', 'Performance EQ active circuit');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (13, 'Scale Length', '30 in (Short Scale)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (13, 'Neck Shape', 'Modern C');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (13, 'Pickups', '1 Split Single-Coil, 1 Single-Coil J-Bass');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (14, 'Resonating Chamber', 'Yes (Hollow Body design)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (14, 'In/Out Connections', 'Headphone out, Aux in, Line out');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (14, 'Power Supply', 'AA battery or AC adapter');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (2, 'Number of Keys', '88');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (2, 'Type of Keys', 'Graded Hammer Standard (GHS) Keyboard');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (2, 'Touch Sensitivity', 'Hard/Medium/Soft/Fixed');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (2, 'Sound Engine', 'Pure CF Sound Engine');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (2, 'Weight', '26 lbs (11.8 kg)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (15, 'Keyboard', '88-key PHA-4 Standard Keyboard with Escapement');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (15, 'Sound Engine', 'SuperNATURAL Piano Sound');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (15, 'Polyphony', '256 voices');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (15, 'Bluetooth Support', 'Yes (Audio & MIDI)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (16, 'Cabinet Style', 'Baby Grand');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (16, 'Sound Modeling', 'Piano Reality Premium Modeling');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (16, 'Keyboard Action', 'Hybrid Grand Keyboard (Wood/Molded)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (16, 'Speakers', '5-speaker Projection Sound system');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (17, 'Piano Type', 'Upright Acoustic');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (17, 'Soundboard', 'Solid Spruce');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (17, 'Height', '48 inches (121 cm)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (17, 'Finish', 'Polished Ebony');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (18, 'Sound Engines', 'V-Piano Technology & SuperNATURAL');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (18, 'Keyboard Action', '88-key PHA-50 Hybrid structure');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (18, 'Control Interface', '9 sliders, 8 encoder knobs with LED rings');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (19, 'Number of Keys', '61');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (19, 'Touch Response', 'Yes (Soft, Medium, Hard, Fixed)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (19, 'Built-in Voices', '622 Voices');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (19, 'Accompaniment Styles', '205 Auto Styles');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (20, 'Keys Type', '61 Box-shape keys with Ivory Feel');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (20, 'Sound Loop Mix', 'Yes (over 12 sets of patterns)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (20, 'Wireless link', 'Bluetooth 4.2');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (21, 'Display', '7-inch color TFT touch screen');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (21, 'Voices Library', '1337 Voices + 56 Drum Kits');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (21, 'Recording', '16-track MIDI recording capacity');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (22, 'Keyboard', '61 keys with velocity sensitivity');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (22, 'Accompaniment', '300 preset styles + user imports');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (22, 'Inputs', 'Mic input with effects, Bluetooth audio');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (23, 'Keyboard', '88-key weighted PHA-4 Standard');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (23, 'Sound Generator', 'ZEN-Core, SuperNATURAL Acoustic/Electric');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (23, 'Interface', 'USB Audio 4x32, 16 RGB pads, color touchscreen');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (3, 'Drum Sound Module', 'TD-17 x 1');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (3, 'Snare Pad', 'PDX-12 x 1 (12-inch double mesh head)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (3, 'Tom Pads', 'PDX-8 x 3 (8-inch double mesh head)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (3, 'Hi-Hat Cymbal', 'VH-10 x 1 (10-inch dual-trigger cymbals)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (24, 'Shell Material', '100% Birch, 6-ply');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (24, 'Configuration', '5-piece shell pack (no cymbals)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (24, 'Hardware Pack', 'Yamaha HW780 included');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (25, 'Shell Material', '6-ply Poplar');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (25, 'Tension Hoops', '1.5mm Triple-Flange Steel');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (25, 'Includes', 'Cymbal stands, Snare stand, Hi-hat stand, Bass pedal');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (26, 'Snare Pad', 'PDX-8 double-mesh pad');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (26, 'Cymbals', 'CY-5 dual-trigger crash/ride pads');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (26, 'Coach Functions', 'Yes (5 modes)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (26, 'Connectivity', 'Bluetooth Audio/MIDI, USB MIDI');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (27, 'Shell Material', 'Aged Siam Oak');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (27, 'Drum Heads', 'Natural Rawhide (11" and 12" heads)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (27, 'Rim Type', 'Comfort Curve rims');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (28, 'Pads', '9 velocity-sensitive pads with LED lights');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (28, 'Memory Capacity', '32 GB internal storage');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (28, 'Audio Outputs', 'Master L/R outputs, 4 direct audio outputs');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (29, 'Bayan Material', 'Heavy Brass, Chrome plated (approx 3kg)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (29, 'Dayan Material', 'Seasoned Sheesham Wood');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (29, 'Accessories', 'Cushion rings, covers, tuning hammer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (30, 'Pads', '10-inch pad with 13 pressure-sensitive segments');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (30, 'Sounds Library', '850 percussion instruments');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (30, 'Effects', 'Realtime D-BEAM controller, multi-effects');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (31, 'Frontplate Material', 'Meranti Wood');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (31, 'Snare System', 'Built-in dual internal wire set');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (31, 'Feet', 'Non-slip rubber feet');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (32, 'Sound Module', 'Built-in, 30 electronic kit presets');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (32, 'Speaker Output', 'Integrated coaxial speaker (3 W)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (32, 'Power Specs', 'AA battery or AC adapter');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (33, 'Key Type', 'Closed-hole keys');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (33, 'Key System', 'Offset G, Undercut tone holes');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (33, 'Finish', 'Nickel-silver plated body');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (34, 'Valves Type', '3 Monel alloy pistons');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (34, 'Bell Diameter', '4-7/8 inches (123 mm)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (34, 'Finish', 'Gold lacquer finish');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (35, 'Body Material', 'Matte ABS Resin');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (35, 'Keys Material', 'Nickel-plated nickel silver');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (35, 'Barrel Length', '65 mm');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (36, 'Key', 'Eb (Alto)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (36, 'Auxiliary Keys', 'High F#, Front F');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (36, 'Thumb Hook', 'Adjustable plastic hook');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (37, 'Key', 'Bb (Diatonic)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (37, 'Holes Count', '10 holes, 20 reeds');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (37, 'Comb Material', 'Molded PVC plastic comb');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (38, 'Headjoint Material', 'Solid Sterling Silver (.925)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (38, 'Key System', 'Open-hole keys, Offset G, Split E mechanism');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (38, 'Footjoint Type', 'C Footjoint');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (39, 'Bell Material', 'Gold Brass, two-piece bell');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (39, 'Bore Size', 'Medium-Large 0.459 in');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (39, 'Valves Material', 'Monel Alloy');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (40, 'Body Material', 'Grenadilla Wood');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (40, 'Keys Finish', 'Silver-plated keys');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (40, 'Thumb Rest', 'Adjustable with strap ring');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (41, 'Neck Type', '62-style neck (improved response)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (41, 'Key Work', 'High F#, Teardrop front F, Low B-C# connection');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (41, 'Engraving', 'Hand-engraved bell details');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (42, 'Key Tuning', 'C (Diatonic)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (42, 'Cover Plate', 'Matte Black Stainless Steel');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (42, 'Reeds Material', 'Phosphor Bronze reeds');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (4, 'Connectivity', 'USB Type-C');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (4, 'Simultaneous I/O', '2 x 2');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (4, 'Number of Preamps', '2 x mic, 2 x instrument');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (4, 'A/D Resolution', '24-bit/192 kHz');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (5, 'Type', 'Dynamic');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (5, 'Polar Pattern', 'Cardioid');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (5, 'Frequency Response', '50Hz - 15kHz');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (5, 'Connector', '3-pin male XLR');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (43, 'Synth Engine', '100% Discrete Analog');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (43, 'Oscillators', '3 Voltage Controlled Oscillators (VCO)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (43, 'Sequencer', '16-step sequencer with parameter locks');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (44, 'Polyphony', '22 voices');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (44, 'Keyboard', '37 keys with velocity sensitivity');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (44, 'Modulation', 'Phase Motion pad, custom LFO routing');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (45, 'Number of Keys', '49 keys');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (45, 'Controllers', 'Pitch bend/Mod lever, D-BEAM controller');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (45, 'Power', 'USB Bus powered');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (46, 'Engine', 'ACB (Analog Circuit Behavior) + sample play');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (46, 'Sample Storage', 'SD card import supported');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (46, 'Out connections', '8 analog outputs, trigger out, MIDI I/O');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (47, 'Simultaneous I/O', '2 x 2');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (47, 'Number of Preamps', '1 Mic, 1 Instrument/Line');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (47, 'Air Mode', 'Yes (adds high-end presence)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (48, 'Simultaneous I/O', '10 x 4');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (48, 'Dynamic Range', '124dB (D/A converter)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (48, 'Expandability', 'ADAT optical input for 8 extra channels');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (49, 'Type', 'Dynamic');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (49, 'Polar Pattern', 'Cardioid');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (49, 'Electromagnetic Shielding', 'Yes (against computer monitor hum)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (49, 'Mounting', 'Integrated yoke mount');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (50, 'Channels', '2 channels, 4 decks control');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (50, 'Drum Kits', 'Built-in TR drum kits (TR-808, TR-909)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (50, 'Interface', 'Midi Out, USB bus powered, 1/4 inch Mic Input');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (101, 'Instrument Type', 'Fiddle');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (101, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (101, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (102, 'Instrument Type', 'Lute');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (102, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (102, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (103, 'Instrument Type', 'Oud');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (103, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (103, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (104, 'Instrument Type', 'Erhu');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (104, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (104, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (105, 'Instrument Type', 'Santoor');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (105, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (105, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (106, 'Instrument Type', 'Tanpura');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (106, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (106, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (107, 'Instrument Type', 'Veena');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (107, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (107, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (108, 'Instrument Type', 'Sarod');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (108, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (108, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (109, 'Instrument Type', 'sitar');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (109, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (109, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (110, 'Instrument Type', 'Banjo');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (110, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (110, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (111, 'Instrument Type', 'Toy Piano');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (111, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (111, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (112, 'Instrument Type', 'Spinet Piano');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (112, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (112, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (113, 'Instrument Type', 'concert Organ');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (113, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (113, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (114, 'Instrument Type', 'Electric Keyboard');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (114, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (114, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (115, 'Instrument Type', 'Melodica');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (115, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (115, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (116, 'Instrument Type', 'MIDI keyboard controller');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (116, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (116, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (117, 'Instrument Type', 'Celesta');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (117, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (117, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (118, 'Instrument Type', 'Clavichord');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (118, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (118, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (119, 'Instrument Type', 'Harpsichord');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (119, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (119, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (120, 'Instrument Type', 'Accordion');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (120, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (120, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (121, 'Instrument Type', 'Timpani(kettle Drum)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (121, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (121, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (122, 'Instrument Type', 'Vibraphone');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (122, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (122, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (123, 'Instrument Type', 'Marimba');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (123, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (123, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (124, 'Instrument Type', 'Xylophone');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (124, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (124, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (125, 'Instrument Type', 'Cowbell');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (125, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (125, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (126, 'Instrument Type', 'Claves');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (126, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (126, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (127, 'Instrument Type', 'Castanet');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (127, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (127, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (128, 'Instrument Type', 'Maracas');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (128, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (128, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (129, 'Instrument Type', 'Triangle');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (129, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (129, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (130, 'Instrument Type', 'Tambourine');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (130, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (130, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (131, 'Instrument Type', 'Basson');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (131, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (131, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (132, 'Instrument Type', 'Recorder');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (132, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (132, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (133, 'Instrument Type', 'Trombone');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (133, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (133, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (134, 'Instrument Type', 'Pan Flute');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (134, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (134, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (135, 'Instrument Type', 'Bugle');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (135, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (135, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (136, 'Instrument Type', 'euphonium');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (136, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (136, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (137, 'Instrument Type', 'French Horn');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (137, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (137, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (138, 'Instrument Type', 'Tuba');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (138, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (138, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (139, 'Instrument Type', 'English Horn (Cor Anglais)');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (139, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (139, 'Finish', 'Natural Lacquer');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (140, 'Instrument Type', 'Cornet');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (140, 'Build Grade', 'Professional');
INSERT INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`) VALUES (140, 'Finish', 'Natural Lacquer');
