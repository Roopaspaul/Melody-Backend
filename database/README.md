# MelodyMart Database Documentation

This directory contains the database schemas, seed scripts, and documentation for **MelodyMart**, a premium musical instrument e-commerce application.

## Database Technology
The project uses **MySQL** as its production relational database. It is configured in the Spring Boot backend (`application.properties`) and supports standard relational integrity, foreign key checks, generated stored columns, and cascade rules.

---

## Directory Structure

```text
database/
├── schema/
│   ├── schema.sql           # Authentication module schemas
│   ├── product_schema.sql   # Product catalog & specifications schemas
│   └── shopping_schema.sql  # Wishlist & Shopping Cart schemas
├── seed/
│   └── melodymart_db_seed.sql # Initial catalog seeding SQL (50 products)
├── migrations/              # Folder for schema migration version files
├── sql/                     # Folder for custom query scripts
└── README.md                # This database documentation file
```

---

## 1. Schema Specifications

### Authentication Module (`database/schema/schema.sql`)
Defines the user identities, account status, security roles, verification codes, and long-lived session management.

* **`users`**: Stores user profiles (customers, employees, administrators). Implements:
  - Alphanumeric unique `username`
  - Unique verified `email` and `phone_number`
  - BCrypt hashed passwords (`password_hash`)
  - A generated column `full_name` computed automatically as `first_name` + ' ' + `last_name`
  - Account status mapping (`PENDING_VERIFICATION`, `ACTIVE`, `LOCKED`, etc.)
* **`email_otp` / `phone_otp`**: Stores temporary 6-digit verification codes sent via email/SMS for registration, password reset, or MFA challenges. Cleaned up automatically `ON DELETE CASCADE` when a user is deleted.
* **`refresh_tokens`**: Manages cryptographically secure long-lived tokens (UUIDs) mapped to user devices for session renewal ("Remember Me").

### Product Catalog Module (`database/schema/product_schema.sql`)
Manages the store structure, brands, inventory details, images, and technical specifications.

* **`categories`**: General classifications (e.g. "String Instruments", "Keyboard Instruments").
* **`sub_categories`**: Finer groupings (e.g. "Guitar" under "String Instruments").
* **`brands`**: Manufacturers (e.g. Yamaha, Fender, Roland).
* **`products`**: Central inventory table managing prices, discounts, stock count, model numbers, warranty terms, and ratings.
* **`product_images`**: Up to 20 CDN links/URLs per product showing different angles. Uses an index to order slides.
* **`product_specifications`**: Key-value metadata table (e.g. key = "Fret Count", value = "24") to prevent sparse columns in the main table.

### Shopping Module (`database/schema/shopping_schema.sql`)
Handles consumer customer saves and active session carts.

* **`wishlist`**: Simple mapping of users to saved/starred products.
* **`cart`**: Unique active cart record per user.
* **`cart_items`**: Line items inside a cart with quantity and locked unit price tracking.

---

## 2. Seed Data (`database/seed/melodymart_db_seed.sql`)
The database seed file contains:
- Predefined categories and subcategories.
- Setup parameters for leading brands (Yamaha, Fender, Roland, Shure, Focusrite).
- 50 catalog items complete with descriptions, model numbers, stock numbers, images, and detailed spec mappings.

This seed script is run automatically by the Spring Boot backend (`DataInitializer.java`) when it detects an empty product catalog database.

---

## 3. Configuration & Local Deployment
To run database setup scripts:
1. Make sure MySQL server is running locally on port `3306`.
2. Connect to the database console:
   ```bash
   mysql -u root -p
   ```
3. Create the database:
   ```sql
   CREATE DATABASE melodymart_db;
   ```
4. Feed schema configurations (order matters due to foreign keys):
   ```bash
   mysql -u root -p melodymart_db < database/schema/schema.sql
   mysql -u root -p melodymart_db < database/schema/product_schema.sql
   mysql -u root -p melodymart_db < database/schema/shopping_schema.sql
   ```
5. Feed initial catalog data:
   ```bash
   mysql -u root -p melodymart_db < database/seed/melodymart_db_seed.sql
   ```
