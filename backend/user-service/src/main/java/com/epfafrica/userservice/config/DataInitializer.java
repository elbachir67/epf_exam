package com.epfafrica.userservice.config;

import com.epfafrica.userservice.model.User;
import com.epfafrica.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    
    @Override
    public void run(String... args) throws Exception {
        log.info("Initializing test data...");
        
        if (userRepository.count() == 0) {
            // Create test users
            User admin = User.builder()
                    .username("admin")
                    .email("admin@epfafrica.com")
                    .password(passwordEncoder.encode("admin123"))
                    .firstName("Admin")
                    .lastName("EPF")
                    .build();
            admin.addRole("ROLE_ADMIN");
            admin.addRole("ROLE_USER");
            
            User student = User.builder()
                    .username("student")
                    .email("student@epfafrica.com")
                    .password(passwordEncoder.encode("student123"))
                    .firstName("Test")
                    .lastName("Student")
                    .build();
            student.addRole("ROLE_USER");
            
            userRepository.save(admin);
            userRepository.save(student);
            
            log.info("Test users created successfully");
        }
    }
}
