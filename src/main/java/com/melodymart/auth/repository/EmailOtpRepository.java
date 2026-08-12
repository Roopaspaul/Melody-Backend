package com.melodymart.auth.repository;

import com.melodymart.auth.entity.EmailOtp;
import com.melodymart.auth.entity.User;
import com.melodymart.auth.entity.enums.OtpPurpose;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface EmailOtpRepository extends JpaRepository<EmailOtp, Long> {
    Optional<EmailOtp> findTopByUserAndOtpCodeAndPurposeAndIsUsedFalseOrderByCreatedAtDesc(
        User user, String otpCode, OtpPurpose purpose
    );
    List<EmailOtp> findByUserAndPurposeAndIsUsedFalse(User user, OtpPurpose purpose);
}
