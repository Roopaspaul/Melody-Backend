package com.melodymart.auth.controller;

import com.melodymart.auth.entity.User;
import com.melodymart.auth.entity.enums.UserRole;
import com.melodymart.auth.entity.enums.AccountStatus;
import com.melodymart.auth.repository.UserRepository;
import com.melodymart.auth.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private AdminService adminService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/dashboard-stats")
    public ResponseEntity<?> getStats() {
        return ResponseEntity.ok(adminService.getDashboardStats());
    }

    @GetMapping("/charts")
    public ResponseEntity<?> getCharts() {
        return ResponseEntity.ok(adminService.getAnalyticsChartsData());
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<?> getAuditLogs() {
        return ResponseEntity.ok(adminService.getAuditLogs());
    }

    @GetMapping("/users")
    public ResponseEntity<?> getAllUsers() {
        List<User> users = userRepository.findAll();
        return ResponseEntity.ok(users);
    }

    @PostMapping("/users/{id}/block")
    public ResponseEntity<?> blockUser(@PathVariable("id") Long userId) {
        adminService.blockUser(userId);
        return ResponseEntity.ok(Map.of("message", "User blocked successfully"));
    }

    @PostMapping("/users/{id}/unblock")
    public ResponseEntity<?> unblockUser(@PathVariable("id") Long userId) {
        adminService.unblockUser(userId);
        return ResponseEntity.ok(Map.of("message", "User unblocked successfully"));
    }

    @PostMapping("/users/{id}/role")
    public ResponseEntity<?> changeRole(@PathVariable("id") Long userId, @RequestBody Map<String, String> request) {
        String roleStr = request.get("role");
        UserRole role = UserRole.valueOf(roleStr);
        adminService.changeUserRole(userId, role);
        return ResponseEntity.ok(Map.of("message", "User role changed successfully"));
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable("id") Long userId) {
        adminService.deleteUser(userId);
        return ResponseEntity.ok(Map.of("message", "User deleted successfully"));
    }

    @PutMapping("/users/{id}")
    public ResponseEntity<?> updateUser(@PathVariable("id") Long id, @RequestBody Map<String, String> request) {
        try {
            String firstName = request.get("firstName");
            String lastName = request.get("lastName");
            String username = request.get("username");
            String email = request.get("email");
            String password = request.get("password");
            UserRole role = UserRole.valueOf(request.get("role"));
            AccountStatus status = AccountStatus.valueOf(request.get("status"));
            
            adminService.updateUser(id, firstName, lastName, username, email, password, role, status);
            return ResponseEntity.ok(Map.of("message", "User updated successfully"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/reports")
    public ResponseEntity<byte[]> downloadReport(
            @RequestParam("type") String reportType,
            @RequestParam("format") String format,
            @RequestParam("start") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam("end") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end) {
        try {
            byte[] data;
            String filename = reportType.toLowerCase() + "_report." + ("pdf".equalsIgnoreCase(format) ? "pdf" : "xlsx");
            String contentType = "pdf".equalsIgnoreCase(format) ? MediaType.APPLICATION_PDF_VALUE : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

            if ("pdf".equalsIgnoreCase(format)) {
                data = adminService.generatePdfReport(reportType, start, end);
            } else {
                data = adminService.generateExcelReport(reportType, start, end);
            }

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + filename)
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(data);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/analytics/daily")
    public ResponseEntity<?> getDailyAnalytics(@RequestParam("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(adminService.getDailyAnalytics(date));
    }

    @GetMapping("/analytics/monthly")
    public ResponseEntity<?> getMonthlyAnalytics(@RequestParam("year") int year, @RequestParam("month") int month) {
        return ResponseEntity.ok(adminService.getMonthlyAnalytics(year, month));
    }

    @GetMapping("/analytics/yearly")
    public ResponseEntity<?> getYearlyAnalytics(@RequestParam("year") int year) {
        return ResponseEntity.ok(adminService.getYearlyAnalytics(year));
    }

    @GetMapping("/analytics/overall")
    public ResponseEntity<?> getOverallAnalytics() {
        return ResponseEntity.ok(adminService.getOverallAnalytics());
    }
}
