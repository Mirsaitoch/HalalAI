package com.halalai.backend.service;

import com.halalai.backend.dto.AuthResponse;
import com.halalai.backend.dto.LoginRequest;
import com.halalai.backend.dto.RegisterRequest;
import com.halalai.backend.model.User;
import com.halalai.backend.repository.UserRepository;
import com.halalai.backend.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider tokenProvider;

    @Mock
    private AuthenticationManager authenticationManager;

    @InjectMocks
    private AuthService authService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        testUser.setPassword("encodedPassword");
        testUser.setEnabled(true);
    }

    @Test
    void testRegisterSuccess() {
        RegisterRequest request = new RegisterRequest("newuser", "new@example.com", "password123");
        
        when(userRepository.existsByUsername("newuser")).thenReturn(false);
        when(userRepository.existsByEmail("new@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encodedPassword");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(1L);
            return user;
        });
        when(tokenProvider.generateToken("newuser", 1L)).thenReturn("test-token");

        AuthResponse response = authService.register(request);

        assertNotNull(response);
        assertEquals("test-token", response.token());
        assertEquals(1L, response.userId());
        assertEquals("newuser", response.username());
        assertEquals("new@example.com", response.email());
        
        verify(userRepository).save(any(User.class));
        verify(tokenProvider).generateToken("newuser", 1L);
    }

    @Test
    void testRegisterWithExistingUsername() {
        RegisterRequest request = new RegisterRequest("existinguser", "new@example.com", "password123");
        
        when(userRepository.existsByUsername("existinguser")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> authService.register(request));
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void testRegisterWithExistingEmail() {
        RegisterRequest request = new RegisterRequest("newuser", "existing@example.com", "password123");
        
        when(userRepository.existsByUsername("newuser")).thenReturn(false);
        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> authService.register(request));
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void testLoginSuccess() {
        LoginRequest request = new LoginRequest("testuser", "password123");
        Authentication authentication = mock(Authentication.class);
        
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenReturn(authentication);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(tokenProvider.generateToken("testuser", 1L)).thenReturn("test-token");

        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertEquals("test-token", response.token());
        assertEquals(1L, response.userId());
        assertEquals("testuser", response.username());
    }

    @Test
    void testLoginWithEmail() {
        LoginRequest request = new LoginRequest("test@example.com", "password123");
        Authentication authentication = mock(Authentication.class);
        
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenReturn(authentication);
        when(userRepository.findByUsername("test@example.com")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));
        when(tokenProvider.generateToken("testuser", 1L)).thenReturn("test-token");

        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertEquals("test-token", response.token());
    }

    @Test
    void testLoginWithDisabledUser() {
        LoginRequest request = new LoginRequest("testuser", "password123");
        testUser.setEnabled(false);
        Authentication authentication = mock(Authentication.class);
        
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenReturn(authentication);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        assertThrows(IllegalArgumentException.class, () -> authService.login(request));
    }

    @Test
    void testRefreshTokenSuccess() {
        String oldToken = "old-token";
        
        when(tokenProvider.getUsernameFromExpiredToken(oldToken)).thenReturn("testuser");
        when(tokenProvider.getUserIdFromExpiredToken(oldToken)).thenReturn(1L);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(tokenProvider.generateToken("testuser", 1L)).thenReturn("new-token");

        AuthResponse response = authService.refreshToken(oldToken);

        assertNotNull(response);
        assertEquals("new-token", response.token());
        assertEquals(1L, response.userId());
        assertEquals("testuser", response.username());
    }

    @Test
    void testRefreshTokenWithInvalidUsername() {
        String oldToken = "old-token";
        
        when(tokenProvider.getUsernameFromExpiredToken(oldToken)).thenReturn(null);

        assertThrows(IllegalArgumentException.class, () -> authService.refreshToken(oldToken));
    }

    @Test
    void testRefreshTokenWithDisabledUser() {
        String oldToken = "old-token";
        testUser.setEnabled(false);
        
        when(tokenProvider.getUsernameFromExpiredToken(oldToken)).thenReturn("testuser");
        when(tokenProvider.getUserIdFromExpiredToken(oldToken)).thenReturn(1L);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        assertThrows(IllegalArgumentException.class, () -> authService.refreshToken(oldToken));
    }
}

