package com.melodymart.config;

import com.melodymart.auth.entity.User;
import com.melodymart.auth.entity.enums.AccountStatus;
import com.melodymart.auth.entity.enums.UserRole;
import com.melodymart.auth.entity.enums.Gender;
import com.melodymart.auth.repository.UserRepository;
import com.melodymart.order.entity.Address;
import com.melodymart.order.entity.enums.AddressType;
import com.melodymart.order.repository.AddressRepository;
import com.melodymart.product.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import java.io.BufferedReader;
import java.io.FileReader;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        // Purge electronic instruments category (Category ID 5)
        System.out.println(">>> Purging electronic instruments category and its products from database...");
        jdbcTemplate.execute("SET FOREIGN_KEY_CHECKS = 0;");
        jdbcTemplate.execute("DELETE FROM products WHERE category_id = 5;");
        jdbcTemplate.execute("DELETE FROM sub_categories WHERE category_id = 5;");
        jdbcTemplate.execute("DELETE FROM categories WHERE id = 5;");
        jdbcTemplate.execute("SET FOREIGN_KEY_CHECKS = 1;");

        // 1. Initialize Users with BCrypt Password Hashing
        if (!userRepository.existsByUsername("roopa_mart")) {
            User admin = new User();
            admin.setFirstName("Roopa");
            admin.setLastName("Mart");
            admin.setFullName("Roopa Mart Admin");
            admin.setUsername("roopa_mart");
            admin.setEmail("roopaspaulkodi@gmail.com");
            admin.setPasswordHash(BCryptUtils.hash("Roopas@2308")); // Hashed password
            admin.setGender(Gender.FEMALE);
            admin.setDateOfBirth(LocalDate.of(1995, 8, 23));
            admin.setStatus(AccountStatus.ACTIVE);
            admin.setRole(UserRole.ROLE_ADMIN);
            admin.setIsEmailVerified(true);
            admin.setIsPhoneVerified(true);
            userRepository.save(admin);

            Address addr = new Address();
            addr.setUser(admin);
            addr.setAddressLine1("Admin HQ");
            addr.setCity("Metropolis");
            addr.setState("HQ State");
            addr.setCountry("MelodyCountry");
            addr.setPostalCode("99999");
            addr.setAddressType(AddressType.WORK);
            addr.setIsDefault(true);
            addressRepository.save(addr);
        } else {
            // Force reset password and status to guarantee user can log in
            userRepository.findByUsernameOrEmail("roopa_mart", "roopa_mart").ifPresent(admin -> {
                admin.setPasswordHash(BCryptUtils.hash("Roopas@2308"));
                admin.setStatus(AccountStatus.ACTIVE);
                admin.setRole(UserRole.ROLE_ADMIN);
                userRepository.save(admin);
            });
        }

        if (!userRepository.existsByUsername("john_guitar")) {
            User john = new User();
            john.setFirstName("John");
            john.setLastName("Guitar");
            john.setFullName("John Guitarist");
            john.setUsername("john_guitar");
            john.setEmail("john.guitar@example.com");
            john.setPasswordHash(BCryptUtils.hash("john@123")); // Hashed password
            john.setGender(Gender.MALE);
            john.setDateOfBirth(LocalDate.of(2000, 1, 1));
            john.setStatus(AccountStatus.PENDING_VERIFICATION);
            john.setRole(UserRole.ROLE_CUSTOMER);
            john.setIsEmailVerified(false);
            john.setIsPhoneVerified(false);
            userRepository.save(john);

            Address addr = new Address();
            addr.setUser(john);
            addr.setAddressLine1("101 Studio Ave");
            addr.setCity("MusicCity");
            addr.setState("CA");
            addr.setCountry("USA");
            addr.setPostalCode("90210");
            addr.setAddressType(AddressType.HOME);
            addr.setIsDefault(true);
            addressRepository.save(addr);
        }

        // 2. Seed catalog database if empty
        if (productRepository.count() == 0) {
            System.out.println(">>> Product catalog is empty. Seeding catalog database from sql seed file...");
            String seedPath = "../database/seed/melodymart_db_seed.sql";
            if (!Files.exists(Paths.get(seedPath))) {
                seedPath = "database/seed/melodymart_db_seed.sql";
            }
            if (!Files.exists(Paths.get(seedPath))) {
                seedPath = "c:/Users/roopa/myproject/database/seed/melodymart_db_seed.sql";
            }
            if (Files.exists(Paths.get(seedPath))) {
                try {
                    executeSqlScript(seedPath);
                    System.out.println(">>> Database seeded successfully with brands, categories, subcategories, and 50 products!");
                } catch (Exception e) {
                    System.err.println(">>> Failed to seed database: " + e.getMessage());
                    e.printStackTrace();
                }
            } else {
                System.err.println(">>> SQL seed file not found at database/seed/melodymart_db_seed.sql or absolute path. Skipping seeding.");
            }
        }
    }

    private void executeSqlScript(String filePath) throws Exception {
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String line;
            StringBuilder statement = new StringBuilder();
            
            // Temporary disable constraints
            jdbcTemplate.execute("SET FOREIGN_KEY_CHECKS = 0;");
            
            while ((line = reader.readLine()) != null) {
                String trimmedLine = line.trim();
                // Skip comments and database selection lines
                if (trimmedLine.isEmpty() || trimmedLine.startsWith("--") || trimmedLine.startsWith("/*") || trimmedLine.startsWith("USE ")) {
                    continue;
                }
                
                statement.append(line).append("\n");
                
                if (trimmedLine.endsWith(";")) {
                    String query = statement.toString().trim();
                    // Remove ending semicolon for execute
                    if (query.endsWith(";")) {
                        query = query.substring(0, query.length() - 1);
                    }
                    if (!query.isEmpty()) {
                        jdbcTemplate.execute(query);
                    }
                    statement.setLength(0);
                }
            }
            
            // Re-enable constraints
            jdbcTemplate.execute("SET FOREIGN_KEY_CHECKS = 1;");
        }
    }
}
