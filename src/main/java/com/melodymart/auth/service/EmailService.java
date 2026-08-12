package com.melodymart.auth.service;

import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public void sendOtpEmail(String toEmail, String firstName, String otpCode) throws Exception {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        helper.setFrom(fromEmail, "MelodyMart");
        helper.setTo(toEmail);
        helper.setSubject("[" + otpCode + "] Verify your MelodyMart Registration");

        String htmlContent = "<html>" +
                "<body style=\"font-family: Arial, sans-serif; background-color: #0b0f19; color: #f4f4f5; padding: 20px;\">" +
                "  <div style=\"max-width: 500px; margin: 0 auto; background-color: #111827; border: 1px solid #1f2937; border-radius: 8px; padding: 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);\">" +
                "    <h2 style=\"color: #8b5cf6; text-align: center; margin-bottom: 20px;\">MelodyMart Verification</h2>" +
                "    <p style=\"font-size: 16px; line-height: 1.5; color: #d1d5db;\">Hi " + firstName + ",</p>" +
                "    <p style=\"font-size: 16px; line-height: 1.5; color: #d1d5db;\">Thank you for registering at <strong>MelodyMart</strong>!</p>" +
                "    <p style=\"font-size: 16px; line-height: 1.5; color: #d1d5db;\">Your email verification code is:</p>" +
                "    <div style=\"background-color: #1f2937; border-radius: 6px; padding: 15px; text-align: center; margin: 20px 0;\">" +
                "      <span style=\"font-size: 24px; font-weight: bold; color: #ffffff; letter-spacing: 4px;\">" + otpCode + "</span>" +
                "    </div>" +
                "    <p style=\"font-size: 14px; color: #9ca3af; text-align: center; margin-top: 30px;\">If you did not request this code, please ignore this email.</p>" +
                "  </div>" +
                "</body>" +
                "</html>";

        helper.setText(htmlContent, true);
        mailSender.send(message);
    }
}
