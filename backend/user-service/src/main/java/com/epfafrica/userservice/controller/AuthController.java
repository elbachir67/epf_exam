package com.epfafrica.userservice.controller;

import com.epfafrica.userservice.dto.ApiResponse;
import com.epfafrica.userservice.dto.JwtResponse;
import com.epfafrica.userservice.dto.LoginRequest;
import com.epfafrica.userservice.dto.RegisterRequest;
import com.epfafrica.userservice.model.User;
import com.epfafrica.userservice.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {
    
    private final AuthService authService;
    
    @PostMapping("/register")
    public ResponseEntity<ApiResponse> registerUser(@Valid @RequestBody RegisterRequest registerRequest) {
        log.info("Register request received for user: {}", registerRequest.getUsername());
        
        User user = authService.registerUser(registerRequest);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("User registered successfully", user));
    }
    
    @PostMapping("/login")
    public ResponseEntity<JwtResponse> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        log.info("Login request received for user: {}", loginRequest.getUsername());
        
        JwtResponse jwtResponse = authService.authenticateUser(loginRequest);
        
        return ResponseEntity.ok(jwtResponse);
    }
    
    @GetMapping("/health")
    public ResponseEntity<ApiResponse> checkHealth() {
        return ResponseEntity.ok(ApiResponse.success("EPF Africa User Service is running"));
    }
}
