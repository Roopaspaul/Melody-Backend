package com.melodymart.config;

import com.melodymart.auth.repository.JwtTokenRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SecurityInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtTokenRepository jwtTokenRepository;

    // Simple IP-based Rate Limiting map: IP -> last request timestamp
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

        // 2. CORS Handling (if applicable, though they are served from same origin)
        // Allow all headers for easy API access
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
        
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);
            return false;
        }

        // 3. Extract and parse JWT from Authorization Header
        String authHeader = request.getHeader("Authorization");
        String username = null;
        String role = null;

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (!JwtUtils.isTokenExpired(token) && jwtTokenRepository.findByToken(token).isPresent()) {
                username = JwtUtils.getUsernameFromToken(token);
                role = JwtUtils.getRoleFromToken(token);
            }
        }

        // Expose username and role to controllers
        if (username != null) {
            request.setAttribute("username", username);
            request.setAttribute("role", role);
        }

        // 4. Role-Based Access Control (RBAC) Enforcement
        String path = request.getRequestURI();

        // Admin paths require ROLE_ADMIN
        if (path.startsWith("/api/admin")) {
            if (role == null) {
                sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "Authentication token is missing or invalid");
                return false;
            }
            if (!"ROLE_ADMIN".equalsIgnoreCase(role)) {
                sendErrorResponse(response, HttpServletResponse.SC_FORBIDDEN, "Access denied: Requires Admin privileges");
                return false;
            }
        }

        // Customer checkout/shopping paths require a logged-in user
        if (path.startsWith("/api/orders/checkout") || path.startsWith("/api/orders/history")) {
            if (username == null) {
                sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "Authentication token is missing or invalid");
                return false;
            }
        }

        return true;
    }

    private void sendErrorResponse(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(String.format("{\"error\": \"%s\", \"status\": %d}", message, status));
    }
}
