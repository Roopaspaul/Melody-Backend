package com.melodymart.auth.repository;

import com.melodymart.auth.entity.JwtToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.List;

@Repository
public interface JwtTokenRepository extends JpaRepository<JwtToken, Long> {
    Optional<JwtToken> findByToken(String token);

    @Transactional
    void deleteByToken(String token);

    @Transactional
    void deleteByUsername(String username);

    List<JwtToken> findByUsername(String username);

    @Transactional
    void deleteByCreatedAtBefore(LocalDateTime threshold);
}
