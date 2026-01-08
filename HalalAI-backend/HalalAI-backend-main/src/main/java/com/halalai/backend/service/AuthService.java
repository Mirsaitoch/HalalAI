package com.halalai.backend.service;

import com.halalai.backend.dto.AuthResponse;
import com.halalai.backend.dto.LoginRequest;
import com.halalai.backend.dto.RegisterRequest;
import com.halalai.backend.model.User;
import com.halalai.backend.repository.UserRepository;
import com.halalai.backend.security.JwtTokenProvider;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final AuthenticationManager authenticationManager;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider tokenProvider,
            AuthenticationManager authenticationManager
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.authenticationManager = authenticationManager;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new IllegalArgumentException("Пользователь с таким именем уже существует");
        }
        if (userRepository.existsByEmail(request.email())) {
            throw new IllegalArgumentException("Пользователь с таким email уже существует");
        }

        User user = new User();
        user.setUsername(request.username());
        user.setEmail(request.email());
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setEnabled(true);

        user = userRepository.save(user);

        String token = tokenProvider.generateToken(user.getUsername(), user.getId());

        return AuthResponse.of(token, user.getId(), user.getUsername(), user.getEmail());
    }

    public AuthResponse login(LoginRequest request) {
        // Аутентификация пользователя
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.usernameOrEmail(),
                        request.password()
                )
        );

        User user = userRepository.findByUsername(request.usernameOrEmail())
                .orElseGet(() -> userRepository.findByEmail(request.usernameOrEmail())
                        .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден")));

        if (!user.getEnabled()) {
            throw new IllegalArgumentException("Аккаунт пользователя отключен");
        }
        String token = tokenProvider.generateToken(user.getUsername(), user.getId());

        return AuthResponse.of(token, user.getId(), user.getUsername(), user.getEmail());
    }

    public AuthResponse refreshToken(String oldToken) {
        String username = tokenProvider.getUsernameFromExpiredToken(oldToken);
        Long userId = tokenProvider.getUserIdFromExpiredToken(oldToken);

        if (username == null) {
            throw new IllegalArgumentException("Не удалось извлечь username из токена");
        }
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        if (!user.getEnabled()) {
            throw new IllegalArgumentException("Аккаунт пользователя отключен");
        }
        if (userId != null && !userId.equals(user.getId())) {
            throw new IllegalArgumentException("Неверный токен");
        }
        String newToken = tokenProvider.generateToken(user.getUsername(), user.getId());

        return AuthResponse.of(newToken, user.getId(), user.getUsername(), user.getEmail());
    }
}

