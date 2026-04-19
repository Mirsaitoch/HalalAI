package com.halalai.backend.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

class JwtTokenProviderTest {

    private JwtTokenProvider tokenProvider;
    private static final String SECRET = "test-secret-key-must-be-at-least-32-characters-long";
    private static final Long EXPIRATION = 3600000L;

    @BeforeEach
    void setUp() {
        tokenProvider = new JwtTokenProvider();
        ReflectionTestUtils.setField(tokenProvider, "secret", SECRET);
        ReflectionTestUtils.setField(tokenProvider, "expiration", EXPIRATION);
    }

    @Test
    void testGenerateToken() {
        String token = tokenProvider.generateToken("user@example.com", 1L);
        assertNotNull(token);
        assertFalse(token.isEmpty());
    }

    @Test
    void testGetUsernameFromToken() {
        String email = "user@example.com";
        String token = tokenProvider.generateToken(email, 1L);
        String extracted = tokenProvider.getUsernameFromToken(token);
        assertEquals(email, extracted);
    }

    @Test
    void testValidateToken() {
        String email = "user@example.com";
        String token = tokenProvider.generateToken(email, 1L);

        UserDetails userDetails = User.builder()
                .username(email)
                .password("password")
                .authorities("ROLE_USER")
                .build();

        assertTrue(tokenProvider.validateToken(token, userDetails));
    }

    @Test
    void testValidateTokenWithWrongEmail() {
        String token = tokenProvider.generateToken("user@example.com", 1L);

        UserDetails userDetails = User.builder()
                .username("other@example.com")
                .password("password")
                .authorities("ROLE_USER")
                .build();

        assertFalse(tokenProvider.validateToken(token, userDetails));
    }

    @Test
    void testGetUsernameFromExpiredToken() {
        ReflectionTestUtils.setField(tokenProvider, "expiration", -1000L);
        String token = tokenProvider.generateToken("user@example.com", 1L);

        ReflectionTestUtils.setField(tokenProvider, "expiration", EXPIRATION);

        String email = tokenProvider.getUsernameFromExpiredToken(token);
        assertEquals("user@example.com", email);
    }

    @Test
    void testGetUserIdFromExpiredToken() {
        ReflectionTestUtils.setField(tokenProvider, "expiration", -1000L);
        String token = tokenProvider.generateToken("user@example.com", 123L);
        ReflectionTestUtils.setField(tokenProvider, "expiration", EXPIRATION);

        Long userId = tokenProvider.getUserIdFromExpiredToken(token);
        assertEquals(123L, userId);
    }

    @Test
    void testIsTokenExpired() {
        ReflectionTestUtils.setField(tokenProvider, "expiration", -1000L);
        String expiredToken = tokenProvider.generateToken("user@example.com", 1L);
        ReflectionTestUtils.setField(tokenProvider, "expiration", EXPIRATION);

        assertTrue(tokenProvider.isTokenExpired(expiredToken));
    }

    @Test
    void testIsTokenNotExpired() {
        String token = tokenProvider.generateToken("user@example.com", 1L);
        assertFalse(tokenProvider.isTokenExpired(token));
    }
}
