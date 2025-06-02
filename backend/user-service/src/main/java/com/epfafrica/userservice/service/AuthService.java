package com.epfafrica.userservice.service;

import com.epfafrica.userservice.dto.JwtResponse;
import com.epfafrica.userservice.dto.LoginRequest;
import com.epfafrica.userservice.dto.RegisterRequest;
import com.epfafrica.userservice.exception.BadRequestException;
import com.epfafrica.userservice.exception.ResourceNotFoundException;
import com.epfafrica.userservice.model.User;
import com.epfafrica.userservice.repository.UserRepository;
import com.epfafrica.userservice.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {
    
    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    
    @Transactional
    public User registerUser(RegisterRequest registerRequest) {
        log.info("Registering new user: {}", registerRequest.getUsername());
        
        if (userRepository.existsByUsername(registerRequest.getUsername())) {
            throw new BadRequestException("Username is already taken!");
        }
        
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            throw new BadRequestException("Email is already in use!");
        }
        
        User user = User.builder()
                .username(registerRequest.getUsername())
                .email(registerRequest.getEmail())
                .password(passwordEncoder.encode(registerRequest.getPassword()))
                .firstName(registerRequest.getFirstName())
                .lastName(registerRequest.getLastName())
                .active(true)
                .build();
        
        user.addRole("ROLE_USER");
        
        User savedUser = userRepository.save(user);
        log.info("User registered successfully: {}", savedUser.getUsername());
        
        return savedUser;
    }
    
    @Transactional(readOnly = true)
    public JwtResponse authenticateUser(LoginRequest loginRequest) {
        log.info("Authenticating user: {}", loginRequest.getUsername());
        
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginRequest.getUsername(),
                        loginRequest.getPassword()
                )
        );
        
        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = tokenProvider.generateToken(authentication);
        
        User user = userRepository.findByUsername(loginRequest.getUsername())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        log.info("User authenticated successfully: {}", user.getUsername());
        
        return JwtResponse.builder()
                .token(jwt)
                .type("Bearer")
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .build();
    }
}
