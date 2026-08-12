package com.melodymart;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class MelodyMartApplication {
    public static void main(String[] args) {
        SpringApplication.run(MelodyMartApplication.class, args);
    }
}
