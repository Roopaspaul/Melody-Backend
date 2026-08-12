package com.melodymart.auth.service;

import com.melodymart.auth.repository.JwtTokenRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;

@Service
public class TokenCleanupService {

    @Autowired
    private JwtTokenRepository jwtTokenRepository;

    // Purge expired tokens (older than 24 hours) every hour
    @Scheduled(cron = "0 0 * * * *")
    public void cleanupExpiredTokens() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(24);
        try {
            jwtTokenRepository.deleteByCreatedAtBefore(threshold);
            System.out.println(">>> Scheduled Task: Successfully purged JWT tokens older than " + threshold);
        } catch (Exception e) {
            System.err.println(">>> Scheduled Task Error: Failed to purge expired JWT tokens: " + e.getMessage());
        }
    }
}
