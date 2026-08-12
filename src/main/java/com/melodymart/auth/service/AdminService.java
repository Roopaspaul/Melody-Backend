package com.melodymart.auth.service;

import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Element;
import com.lowagie.text.FontFactory;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.melodymart.auth.entity.AuditLog;
import com.melodymart.auth.entity.User;
import com.melodymart.auth.entity.enums.AccountStatus;
import com.melodymart.auth.entity.enums.UserRole;
import com.melodymart.auth.repository.AuditLogRepository;
import com.melodymart.auth.repository.UserRepository;
import com.melodymart.order.entity.Order;
import com.melodymart.order.entity.OrderItem;
import com.melodymart.order.entity.enums.OrderStatus;
import com.melodymart.order.repository.OrderRepository;
import com.melodymart.product.entity.Category;
import com.melodymart.product.entity.Product;
import com.melodymart.product.repository.CategoryRepository;
import com.melodymart.product.repository.ProductRepository;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import com.melodymart.config.BCryptUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

@Service
public class AdminService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    // --- 1. Analytics & Statistics ---
    public Map<String, Object> getDashboardStats() {
        LocalDateTime startOfToday = LocalDateTime.of(LocalDate.now(), LocalTime.MIN);
        LocalDateTime startOfMonth = LocalDateTime.of(LocalDate.now().withDayOfMonth(1), LocalTime.MIN);
        LocalDateTime startOfYear = LocalDateTime.of(LocalDate.now().withDayOfYear(1), LocalTime.MIN);

        List<Order> allOrders = orderRepository.findAll();
        List<Product> allProducts = productRepository.findAll();
        List<Category> allCategories = categoryRepository.findAll();
        List<User> allUsers = userRepository.findAll();

        // Calculate Revenue
        BigDecimal totalRevenue = BigDecimal.ZERO;
        BigDecimal todayRevenue = BigDecimal.ZERO;
        BigDecimal monthlyRevenue = BigDecimal.ZERO;
        BigDecimal yearlyRevenue = BigDecimal.ZERO;

        long pendingOrdersCount = 0;
        long deliveredOrdersCount = 0;

        for (Order order : allOrders) {
            BigDecimal amount = order.getTotalPrice(); // using total price
            if (order.getOrderStatus() != OrderStatus.CANCELLED) {
                totalRevenue = totalRevenue.add(amount);
                if (order.getCreatedAt().isAfter(startOfToday)) {
                    todayRevenue = todayRevenue.add(amount);
                }
                if (order.getCreatedAt().isAfter(startOfMonth)) {
                    monthlyRevenue = monthlyRevenue.add(amount);
                }
                if (order.getCreatedAt().isAfter(startOfYear)) {
                    yearlyRevenue = yearlyRevenue.add(amount);
                }
            }

            if (order.getOrderStatus() == OrderStatus.PENDING) {
                pendingOrdersCount++;
            } else if (order.getOrderStatus() == OrderStatus.DELIVERED) {
                deliveredOrdersCount++;
            }
        }

        long activeCustomersCount = allUsers.stream()
                .filter(u -> u.getStatus() == AccountStatus.ACTIVE && u.getRole() == UserRole.ROLE_CUSTOMER)
                .count();

        long outOfStockProductsCount = allProducts.stream()
                .filter(p -> p.getStockQuantity() == 0)
                .count();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalRevenue", totalRevenue);
        stats.put("todayRevenue", todayRevenue);
        stats.put("monthlyRevenue", monthlyRevenue);
        stats.put("yearlyRevenue", yearlyRevenue);
        stats.put("totalOrders", allOrders.size());
        stats.put("pendingOrders", pendingOrdersCount);
        stats.put("deliveredOrders", deliveredOrdersCount);
        stats.put("totalProducts", allProducts.size());
        stats.put("categoriesCount", allCategories.size());
        stats.put("registeredUsers", allUsers.size());
        stats.put("activeCustomers", activeCustomersCount);
        stats.put("outOfStockProducts", outOfStockProductsCount);

        return stats;
    }

    public Map<String, Object> getAnalyticsChartsData() {
        // Group revenue by category
        List<Order> allOrders = orderRepository.findAll().stream()
                .filter(o -> o.getOrderStatus() != OrderStatus.CANCELLED)
                .collect(Collectors.toList());

        Map<String, BigDecimal> categoryRevenue = new HashMap<>();
        Map<String, Integer> productSales = new HashMap<>();

        for (Order order : allOrders) {
            for (OrderItem item : order.getOrderItems()) {
                Product p = item.getProduct();
                if (p != null) {
                    String catName = p.getCategory().getName();
                    BigDecimal itemTotal = item.getPrice().multiply(new BigDecimal(item.getQuantity()));
                    categoryRevenue.put(catName, categoryRevenue.getOrDefault(catName, BigDecimal.ZERO).add(itemTotal));
                    productSales.put(p.getName(), productSales.getOrDefault(p.getName(), 0) + item.getQuantity());
                }
            }
        }

        // Sort products by sales and get top 5
        List<Map.Entry<String, Integer>> topProducts = productSales.entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                .limit(5)
                .collect(Collectors.toList());

        List<Map<String, Object>> topSellingList = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : topProducts) {
            topSellingList.add(Map.of("name", entry.getKey(), "sales", entry.getValue()));
        }

        // Monthly revenue trend (last 6 months)
        Map<String, BigDecimal> monthlyTrend = new LinkedHashMap<>();
        for (int i = 5; i >= 0; i--) {
            LocalDate monthDate = LocalDate.now().minusMonths(i);
            String monthName = monthDate.getMonth().toString() + " " + monthDate.getYear();
            monthlyTrend.put(monthName, BigDecimal.ZERO);
        }

        for (Order order : allOrders) {
            LocalDateTime created = order.getCreatedAt();
            String monthName = created.getMonth().toString() + " " + created.getYear();
            if (monthlyTrend.containsKey(monthName)) {
                monthlyTrend.put(monthName, monthlyTrend.get(monthName).add(order.getTotalPrice()));
            }
        }

        Map<String, Object> charts = new HashMap<>();
        charts.put("categoryRevenue", categoryRevenue);
        charts.put("topSellingProducts", topSellingList);
        charts.put("monthlyRevenueTrend", monthlyTrend);

        return charts;
    }

    // --- 2. Report Generation ---
    public byte[] generateExcelReport(String reportType, LocalDate start, LocalDate end) throws IOException {
        Workbook workbook = new XSSFWorkbook();
        Sheet sheet = workbook.createSheet(reportType + " Report");
        
        Row header = sheet.createRow(0);
        CellStyle headerStyle = workbook.createCellStyle();
        Font headerFont = workbook.createFont();
        headerFont.setBold(true);
        headerStyle.setFont(headerFont);

        if ("SALES".equalsIgnoreCase(reportType) || "REVENUE".equalsIgnoreCase(reportType)) {
            String[] headers = {"Order ID", "Customer", "Date", "Status", "Shipping Charge", "Tax", "Total Price"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            List<Order> orders = orderRepository.findAll().stream()
                    .filter(o -> !o.getCreatedAt().toLocalDate().isBefore(start) && !o.getCreatedAt().toLocalDate().isAfter(end))
                    .collect(Collectors.toList());

            int rowIdx = 1;
            for (Order o : orders) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(o.getId());
                row.createCell(1).setCellValue(o.getUser().getFullName());
                row.createCell(2).setCellValue(o.getCreatedAt().toString());
                row.createCell(3).setCellValue(o.getOrderStatus().toString());
                row.createCell(4).setCellValue(o.getShippingCharge().doubleValue());
                row.createCell(5).setCellValue(o.getTaxCharge().doubleValue());
                row.createCell(6).setCellValue(o.getTotalPrice().doubleValue());
            }
        } else if ("PRODUCT".equalsIgnoreCase(reportType)) {
            String[] headers = {"Product ID", "Name", "SKU", "Category", "Price", "Discount %", "Stock", "Rating"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            List<Product> products = productRepository.findAll();
            int rowIdx = 1;
            for (Product p : products) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(p.getId());
                row.createCell(1).setCellValue(p.getName());
                row.createCell(2).setCellValue(p.getSku());
                row.createCell(3).setCellValue(p.getCategory().getName());
                row.createCell(4).setCellValue(p.getPrice().doubleValue());
                row.createCell(5).setCellValue(p.getDiscountPercentage().doubleValue());
                row.createCell(6).setCellValue(p.getStockQuantity());
                row.createCell(7).setCellValue(p.getRating().doubleValue());
            }
        } else { // CUSTOMER report
            String[] headers = {"User ID", "Username", "Email", "Full Name", "Phone", "Role", "Status", "Created At"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            List<User> users = userRepository.findAll();
            int rowIdx = 1;
            for (User u : users) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(u.getId());
                row.createCell(1).setCellValue(u.getUsername());
                row.createCell(2).setCellValue(u.getEmail());
                row.createCell(3).setCellValue(u.getFullName());
                row.createCell(4).setCellValue(u.getPhoneNumber() != null ? u.getPhoneNumber() : "");
                row.createCell(5).setCellValue(u.getRole().toString());
                row.createCell(6).setCellValue(u.getStatus().toString());
                row.createCell(7).setCellValue(u.getCreatedAt().toString());
            }
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        workbook.write(out);
        workbook.close();
        return out.toByteArray();
    }

    public byte[] generatePdfReport(String reportType, LocalDate start, LocalDate end) throws DocumentException {
        Document document = new Document();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        PdfWriter.getInstance(document, out);
        document.open();

        com.lowagie.text.Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
        Paragraph title = new Paragraph("MelodyMart - " + reportType + " Report", titleFont);
        title.setAlignment(Element.ALIGN_CENTER);
        document.add(title);
        document.add(new Paragraph("Date Range: " + start + " to " + end));
        document.add(new Paragraph("\n"));

        if ("SALES".equalsIgnoreCase(reportType) || "REVENUE".equalsIgnoreCase(reportType)) {
            PdfPTable table = new PdfPTable(6);
            table.setWidthPercentage(100);
            table.addCell("ID");
            table.addCell("Customer");
            table.addCell("Date");
            table.addCell("Status");
            table.addCell("Tax");
            table.addCell("Total Price");

            List<Order> orders = orderRepository.findAll().stream()
                    .filter(o -> !o.getCreatedAt().toLocalDate().isBefore(start) && !o.getCreatedAt().toLocalDate().isAfter(end))
                    .collect(Collectors.toList());

            for (Order o : orders) {
                table.addCell(String.valueOf(o.getId()));
                table.addCell(o.getUser().getFullName());
                table.addCell(o.getCreatedAt().toLocalDate().toString());
                table.addCell(o.getOrderStatus().toString());
                table.addCell(o.getTaxCharge().toString());
                table.addCell(o.getTotalPrice().toString());
            }
            document.add(table);
        } else if ("PRODUCT".equalsIgnoreCase(reportType)) {
            PdfPTable table = new PdfPTable(6);
            table.setWidthPercentage(100);
            table.addCell("ID");
            table.addCell("Name");
            table.addCell("Category");
            table.addCell("Price");
            table.addCell("Stock");
            table.addCell("Rating");

            List<Product> products = productRepository.findAll();
            for (Product p : products) {
                table.addCell(String.valueOf(p.getId()));
                table.addCell(p.getName());
                table.addCell(p.getCategory().getName());
                table.addCell(p.getPrice().toString());
                table.addCell(String.valueOf(p.getStockQuantity()));
                table.addCell(p.getRating().toString());
            }
            document.add(table);
        } else { // CUSTOMER
            PdfPTable table = new PdfPTable(6);
            table.setWidthPercentage(100);
            table.addCell("ID");
            table.addCell("Username");
            table.addCell("Email");
            table.addCell("Full Name");
            table.addCell("Role");
            table.addCell("Status");

            List<User> users = userRepository.findAll();
            for (User u : users) {
                table.addCell(String.valueOf(u.getId()));
                table.addCell(u.getUsername());
                table.addCell(u.getEmail());
                table.addCell(u.getFullName());
                table.addCell(u.getRole().toString());
                table.addCell(u.getStatus().toString());
            }
            document.add(table);
        }

        document.close();
        return out.toByteArray();
    }

    // --- 3. User operations ---
    public void blockUser(Long userId) {
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
        u.setStatus(AccountStatus.LOCKED);
        userRepository.save(u);
        logAction(null, "ADMIN", "BLOCK_USER", "Blocked user with ID: " + userId + ", username: " + u.getUsername());
    }

    public void unblockUser(Long userId) {
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
        u.setStatus(AccountStatus.ACTIVE);
        userRepository.save(u);
        logAction(null, "ADMIN", "UNBLOCK_USER", "Unblocked user with ID: " + userId + ", username: " + u.getUsername());
    }

    public void changeUserRole(Long userId, UserRole role) {
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
        u.setRole(role);
        userRepository.save(u);
        logAction(null, "ADMIN", "CHANGE_ROLE", "Changed user " + u.getUsername() + " role to " + role);
    }

    public void deleteUser(Long userId) {
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
        userRepository.delete(u);
        logAction(null, "ADMIN", "DELETE_USER", "Deleted user ID: " + userId + ", username: " + u.getUsername());
    }

    public void updateUser(Long userId, String firstName, String lastName, String username, String email, String password, UserRole role, AccountStatus status) {
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
        
        Optional<User> checkUsername = userRepository.findByUsername(username);
        if (checkUsername.isPresent() && !checkUsername.get().getId().equals(userId)) {
            throw new IllegalArgumentException("Username is already taken");
        }
        Optional<User> checkEmail = userRepository.findByEmail(email);
        if (checkEmail.isPresent() && !checkEmail.get().getId().equals(userId)) {
            throw new IllegalArgumentException("Email is already registered");
        }

        u.setFirstName(firstName);
        u.setLastName(lastName);
        u.setFullName((firstName != null ? firstName : "") + " " + (lastName != null ? lastName : ""));
        u.setUsername(username);
        u.setEmail(email);
        if (password != null && !password.trim().isEmpty()) {
            u.setPasswordHash(BCryptUtils.hash(password));
        }
        u.setRole(role);
        u.setStatus(status);
        userRepository.save(u);
        logAction(null, "ADMIN", "UPDATE_USER", "Updated user details for username: " + username + " (ID: " + userId + ")");
    }

    public List<AuditLog> getAuditLogs() {
        return auditLogRepository.findAllByOrderByCreatedAtDesc();
    }

    public void logAction(Long userId, String username, String action, String details) {
        AuditLog log = new AuditLog(userId, username, action, details, "SYSTEM");
        auditLogRepository.save(log);
    }

    // --- 4. Business Analytics Operations ---
    public Map<String, Object> getDailyAnalytics(LocalDate date) {
        LocalDateTime start = LocalDateTime.of(date, LocalTime.MIN);
        LocalDateTime end = LocalDateTime.of(date, LocalTime.MAX);
        List<Order> orders = orderRepository.findByCreatedAtBetween(start, end);

        BigDecimal revenue = BigDecimal.ZERO;
        long transactions = 0;
        for (Order o : orders) {
            if (o.getOrderStatus() != OrderStatus.CANCELLED) {
                revenue = revenue.add(o.getTotalPrice());
                transactions++;
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("date", date.toString());
        result.put("revenue", revenue);
        result.put("transactionsCount", transactions);
        result.put("orders", orders);
        return result;
    }

    public Map<String, Object> getMonthlyAnalytics(int year, int month) {
        LocalDate firstDay = LocalDate.of(year, month, 1);
        LocalDateTime start = LocalDateTime.of(firstDay, LocalTime.MIN);
        LocalDateTime end = LocalDateTime.of(firstDay.plusMonths(1).minusDays(1), LocalTime.MAX);
        List<Order> orders = orderRepository.findByCreatedAtBetween(start, end);

        BigDecimal revenue = BigDecimal.ZERO;
        long transactions = 0;
        for (Order o : orders) {
            if (o.getOrderStatus() != OrderStatus.CANCELLED) {
                revenue = revenue.add(o.getTotalPrice());
                transactions++;
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("year", year);
        result.put("month", month);
        result.put("revenue", revenue);
        result.put("transactionsCount", transactions);
        result.put("orders", orders);
        return result;
    }

    public Map<String, Object> getYearlyAnalytics(int year) {
        LocalDate firstDay = LocalDate.of(year, 1, 1);
        LocalDateTime start = LocalDateTime.of(firstDay, LocalTime.MIN);
        LocalDateTime end = LocalDateTime.of(LocalDate.of(year, 12, 31), LocalTime.MAX);
        List<Order> orders = orderRepository.findByCreatedAtBetween(start, end);

        BigDecimal revenue = BigDecimal.ZERO;
        long transactions = 0;
        for (Order o : orders) {
            if (o.getOrderStatus() != OrderStatus.CANCELLED) {
                revenue = revenue.add(o.getTotalPrice());
                transactions++;
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("year", year);
        result.put("revenue", revenue);
        result.put("transactionsCount", transactions);
        result.put("orders", orders);
        return result;
    }

    public Map<String, Object> getOverallAnalytics() {
        List<Order> orders = orderRepository.findAll();

        BigDecimal revenue = BigDecimal.ZERO;
        long transactions = 0;
        for (Order o : orders) {
            if (o.getOrderStatus() != OrderStatus.CANCELLED) {
                revenue = revenue.add(o.getTotalPrice());
                transactions++;
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("revenue", revenue);
        result.put("transactionsCount", transactions);
        result.put("orders", orders);
        return result;
    }
}
