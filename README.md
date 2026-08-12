# MelodyMart - Backend

This repository houses the server-side REST APIs, database schema/seeding, and email notification microservices for **MelodyMart**, an online musical instrument storefront.

## 🚀 Technologies

* **Core Platform**: Java 21
* **Framework**: Spring Boot 3.x
* **Build Tool**: Maven
* **Data Access**: Spring Data JPA & Hibernate
* **Database**: MySQL 8.x
* **Email Service**: Spring Boot Mail Starter (Gmail SMTP)

---

## 📂 Project Structure

```text
backend/
├── database/              # Database schemas, seeds, and migrations
│   ├── schema/            # SQL scripts for database tables initialization
│   ├── seed/              # Product and store seed files (melodymart_db_seed.sql)
│   ├── migrations/        # Schema migration logs
│   ├── sql/               # Custom SQL maintenance scripts
│   └── README.md          # MySQL database configurations doc
├── src/
│   ├── main/
│   │   ├── java/com/melodymart/
│   │   │   ├── auth/      # Otp, User login, Registration, Token management
│   │   │   ├── config/    # Security filters, Initializers, CORS settings
│   │   │   ├── order/     # Address details, payment, orders endpoint
│   │   │   ├── product/   # Store inventory, categories, brand properties
│   │   │   └── shopping/  # Store wishlist and shopping cart repositories
│   │   └── resources/
│   │       └── application.properties # Main Spring Boot properties
├── .env.example           # Environment template file
├── .gitignore             # Git ignored patterns
├── pom.xml                # Maven configuration file
└── README.md              # Backend information setup
```

---

## 🔑 Environment Configuration

Spring Boot reads sensitive credentials dynamically from environment variables.

### Local Variables Setup
1. Create a `.env` file in the root of the backend project directory (duplicate `.env.example`).
2. Add your database username, password, and SMTP configurations:
   ```properties
   SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/melodymart_db?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
   SPRING_DATASOURCE_USERNAME=root
   SPRING_DATASOURCE_PASSWORD=your_mysql_password
   
   SPRING_MAIL_USERNAME=your-email@gmail.com
   SPRING_MAIL_PASSWORD=your-gmail-app-password
   ```

---

## 🛠️ Run & Execute Locally

### Prerequisites
* Java Development Kit (JDK) 21 installed.
* Maven installed and configured.
* MySQL Server running.

### 1. Compile the Project
To check syntax and compile all source classes:
```bash
mvn clean compile
```

### 2. Run the Spring Boot Server
You can run the server directly using the Maven plugin:
```bash
mvn spring-boot:run
```
* **Base API Address**: `http://localhost:8080`

> [!NOTE]
> On server startup, `DataInitializer.java` will scan `database/seed/melodymart_db_seed.sql`. If the MySQL database is empty, it will seed all categories, subcategories, brands, products, and images automatically.
