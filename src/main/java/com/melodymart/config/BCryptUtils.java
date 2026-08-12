package com.melodymart.config;

import org.mindrot.jbcrypt.BCrypt;

public class BCryptUtils {

    public static String hash(String plainPassword) {
        if (plainPassword == null) return null;
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(10));
    }

    public static boolean verify(String plainPassword, String hashedPassword) {
        if (plainPassword == null || hashedPassword == null) return false;
        try {
            return BCrypt.checkpw(plainPassword, hashedPassword);
        } catch (Exception e) {
            // fallback in case database password was not hashed yet (e.g. legacy data)
            return plainPassword.equals(hashedPassword);
        }
    }
}
