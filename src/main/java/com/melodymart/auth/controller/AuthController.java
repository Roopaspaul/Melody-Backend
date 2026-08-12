package com.melodymart.auth.controller;

import com.melodymart.auth.dto.UserRegistrationDto;
import com.melodymart.auth.entity.EmailOtp;
import com.melodymart.auth.entity.User;
import com.melodymart.auth.entity.JwtToken;
import com.melodymart.auth.entity.AuditLog;
import com.melodymart.auth.entity.enums.AccountStatus;
import com.melodymart.auth.entity.enums.OtpPurpose;
import com.melodymart.auth.entity.enums.UserRole;
import com.melodymart.auth.repository.EmailOtpRepository;
import com.melodymart.auth.repository.UserRepository;
import com.melodymart.auth.repository.JwtTokenRepository;
import com.melodymart.auth.repository.AuditLogRepository;
import com.melodymart.auth.service.EmailService;
import com.melodymart.config.BCryptUtils;
import com.melodymart.config.JwtUtils;
import com.melodymart.order.entity.Address;
import com.melodymart.order.entity.enums.AddressType;
import com.melodymart.order.repository.AddressRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EmailOtpRepository emailOtpRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private EmailService emailService;

    @Autowired
    private JwtTokenRepository jwtTokenRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@Valid @RequestBody UserRegistrationDto dto) {
        if (userRepository.existsByUsername(dto.getUsername())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Username is already taken"));
        }
        if (userRepository.existsByEmail(dto.getEmail())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Email is already registered"));
        }

        // Save User with BCrypt password hashing
        User user = new User();
        user.setFirstName(dto.getFirstName());
        user.setLastName(dto.getLastName());
        user.setFullName(dto.getFirstName() + " " + dto.getLastName());
        user.setUsername(dto.getUsername());
        user.setEmail(dto.getEmail());
        user.setPasswordHash(BCryptUtils.hash(dto.getPassword())); // BCrypt encryption
        user.setPhoneNumber(dto.getPhoneNumber());
        user.setGender(dto.getGender());
        user.setDateOfBirth(dto.getDateOfBirth());
        user.setStatus(AccountStatus.PENDING_VERIFICATION);
        user.setRole(UserRole.ROLE_CUSTOMER);
        user.setIsEmailVerified(false);
        user.setIsPhoneVerified(false);
        user = userRepository.save(user);

        // Save default Address
        Address address = new Address();
        address.setUser(user);
        address.setAddressLine1("Primary Street");
        address.setCity("Cityville");
        address.setState("State");
        address.setCountry("Country");
        address.setPostalCode("10000");
        address.setAddressType(AddressType.HOME);
        address.setIsDefault(true);
        addressRepository.save(address);

        // Send OTP
        sendNewOtp(user, OtpPurpose.REGISTRATION_VERIFICATION);

        return ResponseEntity.ok(Map.of(
            "message", "Registration successful. Please verify the OTP sent to your email.",
            "userId", user.getId(),
            "username", user.getUsername()
        ));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<?> verifyOtp(HttpServletRequest servletRequest, @RequestBody Map<String, String> request) {
        String username = request.get("username");
        String otpCode = request.get("otpCode");

        Optional<User> userOpt = userRepository.findByUsername(username);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "User not found"));
        }
        User user = userOpt.get();

        Optional<EmailOtp> otpOpt = emailOtpRepository.findTopByUserAndOtpCodeAndPurposeAndIsUsedFalseOrderByCreatedAtDesc(
            user, otpCode, OtpPurpose.REGISTRATION_VERIFICATION
        );

        if (otpOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Invalid verification code"));
        }

        EmailOtp otp = otpOpt.get();
        if (otp.isExpired()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Verification code has expired"));
        }

        // Mark OTP used
        otp.setIsUsed(true);
        emailOtpRepository.save(otp);

        // Verify User
        user.setIsEmailVerified(true);
        user.setIsPhoneVerified(true);
        user.setStatus(AccountStatus.ACTIVE);
        userRepository.save(user);

        // Generate JWT token for user
        String token = JwtUtils.generateToken(user.getUsername(), user.getRole().toString());

        // Save token to DB
        jwtTokenRepository.save(new JwtToken(token, user.getUsername()));

        // Log user login
        logUserActivity(user.getId(), user.getUsername(), "LOGIN", "User logged in via OTP verification", servletRequest);

        return ResponseEntity.ok(Map.of(
            "token", token,
            "user", user
        ));
    }

    @PostMapping("/login")
    public ResponseEntity<?> loginUser(HttpServletRequest servletRequest, @RequestBody Map<String, String> request) {
        String identifier = request.get("identifier");
        String password = request.get("password");

        Optional<User> userOpt = userRepository.findByUsernameOrEmail(identifier, identifier);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Invalid username/email or password"));
        }

        User user = userOpt.get();
        
        // Verify via BCrypt
        if (!BCryptUtils.verify(password, user.getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Invalid username/email or password"));
        }

        if (user.getStatus() == AccountStatus.PENDING_VERIFICATION) {
            sendNewOtp(user, OtpPurpose.REGISTRATION_VERIFICATION);
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                "message", "Account verification pending. A new OTP has been sent to your email.",
                "username", user.getUsername(),
                "status", "PENDING_VERIFICATION"
            ));
        }

        if (user.getStatus() == AccountStatus.LOCKED || user.getStatus() == AccountStatus.SUSPENDED) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Your account is locked or suspended. Please contact admin."));
        }

        // Generate JWT Token
        String token = JwtUtils.generateToken(user.getUsername(), user.getRole().toString());

        // Save token to DB
        jwtTokenRepository.save(new JwtToken(token, user.getUsername()));

        // Log user login
        logUserActivity(user.getId(), user.getUsername(), "LOGIN", "User logged in", servletRequest);

        return ResponseEntity.ok(Map.of(
            "token", token,
            "user", user
        ));
    }

    @PostMapping("/resend-otp")
    public ResponseEntity<?> resendOtp(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        Optional<User> userOpt = userRepository.findByUsername(username);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "User not found"));
        }
        User user = userOpt.get();
        sendNewOtp(user, OtpPurpose.REGISTRATION_VERIFICATION);
        return ResponseEntity.ok(Map.of("message", "Verification code resent successfully"));
    }

    // --- FORGOT PASSWORD FLOW ---

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        if (email == null || email.trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Email is required"));
        }

        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "Email is not registered"));
        }

        User user = userOpt.get();
        sendNewOtp(user, OtpPurpose.PASSWORD_RESET);

        return ResponseEntity.ok(Map.of("message", "Password reset OTP has been sent to your email."));
    }

    @PostMapping("/verify-reset-otp")
    public ResponseEntity<?> verifyResetOtp(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String otpCode = request.get("otpCode");

        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "User not found"));
        }
        User user = userOpt.get();

        Optional<EmailOtp> otpOpt = emailOtpRepository.findTopByUserAndOtpCodeAndPurposeAndIsUsedFalseOrderByCreatedAtDesc(
            user, otpCode, OtpPurpose.PASSWORD_RESET
        );

        if (otpOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Invalid or wrong OTP code"));
        }

        EmailOtp otp = otpOpt.get();
        if (otp.isExpired()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "OTP has expired"));
        }

        return ResponseEntity.ok(Map.of("message", "OTP verified. Proceed to change password."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String otpCode = request.get("otpCode");
        String password = request.get("password");

        if (password == null || password.length() < 6) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Password must be at least 6 characters"));
        }

        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "User not found"));
        }
        User user = userOpt.get();

        Optional<EmailOtp> otpOpt = emailOtpRepository.findTopByUserAndOtpCodeAndPurposeAndIsUsedFalseOrderByCreatedAtDesc(
            user, otpCode, OtpPurpose.PASSWORD_RESET
        );

        if (otpOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Invalid or expired OTP"));
        }

        EmailOtp otp = otpOpt.get();
        if (otp.isExpired()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "OTP has expired"));
        }

        // Mark OTP used
        otp.setIsUsed(true);
        emailOtpRepository.save(otp);

        // Update password using BCrypt
        user.setPasswordHash(BCryptUtils.hash(password));
        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "Password has been reset successfully. You can now login."));
    }

    // --- PRIVATE UTILS ---

    private void sendNewOtp(User user, OtpPurpose purpose) {
        // Generate code
        String code = String.format("%06d", new Random().nextInt(999999));

        // Invalidate old OTPs of same purpose
        List<EmailOtp> oldOtps = emailOtpRepository.findByUserAndPurposeAndIsUsedFalse(user, purpose);
        for (EmailOtp old : oldOtps) {
            old.setIsUsed(true);
        }
        emailOtpRepository.saveAll(oldOtps);

        // Save new OTP
        EmailOtp otp = new EmailOtp();
        otp.setUser(user);
        otp.setOtpCode(code);
        otp.setPurpose(purpose);
        otp.setExpiryTime(LocalDateTime.now().plusMinutes(10));
        otp.setIsUsed(false);
        emailOtpRepository.save(otp);

        System.out.println(">>> [SECURITY Relayed OTP] " + purpose + " Code generated for user " + user.getUsername() + " (" + user.getEmail() + "): " + code);

        // Send Email
        try {
            emailService.sendOtpEmail(user.getEmail(), user.getFirstName(), code);
        } catch (Exception e) {
            System.err.println("Failed to send verification email: " + e.getMessage());
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            jwtTokenRepository.deleteByToken(token);
            String username = JwtUtils.getUsernameFromToken(token);
            if (username != null) {
                Optional<User> userOpt = userRepository.findByUsername(username);
                if (userOpt.isPresent()) {
                    User user = userOpt.get();
                    logUserActivity(user.getId(), username, "LOGOUT", "User logged out", request);
                }
            }
        }
        return ResponseEntity.ok(Map.of("message", "Logged out successfully"));
    }

    @PostMapping("/log-activity")
    public ResponseEntity<?> logActivity(HttpServletRequest request, @RequestBody Map<String, String> payload) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "User not logged in"));
        }
        String action = payload.get("action");
        String details = payload.get("details");
        if (action == null || action.trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Action is required"));
        }
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
        logUserActivity(user.getId(), username, action, details, request);
        return ResponseEntity.ok(Map.of("message", "Activity logged successfully"));
    }

    @GetMapping("/activity-history")
    public ResponseEntity<?> getActivityHistory(HttpServletRequest request) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "User not logged in"));
        }
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
        List<AuditLog> logs = auditLogRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
        return ResponseEntity.ok(logs);
    }

    private void logUserActivity(Long userId, String username, String action, String details, HttpServletRequest request) {
        String ipAddress = request != null ? request.getRemoteAddr() : "SYSTEM";
        AuditLog log = new AuditLog(userId, username, action, details, ipAddress);
        auditLogRepository.save(log);
    }
}
