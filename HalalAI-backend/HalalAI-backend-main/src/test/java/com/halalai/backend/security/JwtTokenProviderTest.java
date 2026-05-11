package com.halalai.backend.security;

import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import java.lang.reflect.Field;
import java.nio.charset.StandardCharsets;
import java.util.Date;

import static org.junit.jupiter.api.Assertions.*;

class JwtTokenProviderTest {

    @Test
    void generateToken_andValidateToken_happyPath() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF"); // 32 bytes
        setField(sut, "expiration", 60_000L);

        var token = sut.generateToken("a@b.com", 123L);
        assertNotNull(token);

        var userDetails = User.withUsername("a@b.com").password("x").authorities("ROLE_USER").build();
        assertTrue(sut.validateToken(token, userDetails));
        assertEquals("a@b.com", sut.getUsernameFromToken(token));
    }

    @Test
    void validateToken_returnsFalse_whenUsernameMismatch() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        var token = sut.generateToken("a@b.com", 1L);
        var other = User.withUsername("x@y.com").password("x").authorities("ROLE_USER").build();
        assertFalse(sut.validateToken(token, other));
    }

    @Test
    void isTokenExpired_returnsTrue_forExpiredToken() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 1L);

        var token = sut.generateToken("a@b.com", 1L);
        Thread.sleep(5);

        assertTrue(sut.isTokenExpired(token));
    }

    @Test
    void getUsernameFromExpiredToken_returnsSubject_evenWhenExpired() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 1L);

        var token = sut.generateToken("a@b.com", 7L);
        Thread.sleep(5);

        assertEquals("a@b.com", sut.getUsernameFromExpiredToken(token));
    }

    @Test
    void getUserIdFromExpiredToken_returnsUserId_evenWhenExpired() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 1L);

        var token = sut.generateToken("a@b.com", 777L);
        Thread.sleep(5);

        assertEquals(777L, sut.getUserIdFromExpiredToken(token));
    }

    @Test
    void getUsernameFromExpiredToken_throwsForMalformedToken() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        assertThrows(Exception.class, () -> sut.getUsernameFromExpiredToken("not-a-jwt"));
    }

    @Test
    void validateToken_returnsFalse_whenSignatureInvalid() throws Exception {
        var sut1 = new JwtTokenProvider();
        setField(sut1, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut1, "expiration", 60_000L);
        var token = sut1.generateToken("a@b.com", 1L);

        var sut2 = new JwtTokenProvider();
        setField(sut2, "secret", "DIFFERENT_SECRET_0123456789ABCDEF0123");
        setField(sut2, "expiration", 60_000L);

        var userDetails = User.withUsername("a@b.com").password("x").authorities("ROLE_USER").build();
        assertFalse(sut2.validateToken(token, userDetails));
    }

    @Test
    void getUsernameFromToken_throwsExpiredJwtException_whenExpired() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 1L);

        var token = sut.generateToken("a@b.com", 1L);
        Thread.sleep(5);

        assertThrows(io.jsonwebtoken.ExpiredJwtException.class, () -> sut.getUsernameFromToken(token));
    }

    @Test
    void getUsernameFromToken_throwsMalformedJwtException_forGarbage() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        assertThrows(io.jsonwebtoken.MalformedJwtException.class, () -> sut.getUsernameFromToken("abc.def.ghi"));
    }

    @Test
    void getUserIdFromExpiredToken_returnsNull_whenUserIdNotNumber() throws Exception {
        var sut = new JwtTokenProvider();
        var secret = "0123456789ABCDEF0123456789ABCDEF";
        setField(sut, "secret", secret);
        setField(sut, "expiration", 1L);

        var key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        var now = new Date();
        var expired = new Date(now.getTime() - 5);

        var token = Jwts.builder()
                .claim("userId", "not-a-number")
                .subject("a@b.com")
                .issuedAt(now)
                .expiration(expired)
                .signWith(key)
                .compact();

        assertNull(sut.getUserIdFromExpiredToken(token));
    }

    @Test
    void getUserIdFromExpiredToken_returnsNull_onMalformedToken() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        assertNull(sut.getUserIdFromExpiredToken("not-a-jwt"));
    }

    @Test
    void getUsernameFromExpiredToken_worksForNonExpiredToken() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        var token = sut.generateToken("live@b.com", 5L);
        assertEquals("live@b.com", sut.getUsernameFromExpiredToken(token));
    }

    @Test
    void getUserIdFromExpiredToken_worksForNonExpiredToken() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        var token = sut.generateToken("live@b.com", 555L);
        assertEquals(555L, sut.getUserIdFromExpiredToken(token));
    }

    @Test
    void isTokenExpired_returnsTrue_onParsingError() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        assertTrue(sut.isTokenExpired("not-a-jwt"));
    }

    @Test
    void getUsernameFromToken_throwsAndHitsGenericCatch_whenTokenNull() throws Exception {
        var sut = new JwtTokenProvider();
        setField(sut, "secret", "0123456789ABCDEF0123456789ABCDEF");
        setField(sut, "expiration", 60_000L);

        assertThrows(IllegalArgumentException.class, () -> sut.getUsernameFromToken(null));
    }

    @Test
    void getUserIdFromExpiredToken_returnsNull_whenUserIdNotNumber_andTokenNotExpired() throws Exception {
        var sut = new JwtTokenProvider();
        var secret = "0123456789ABCDEF0123456789ABCDEF";
        setField(sut, "secret", secret);
        setField(sut, "expiration", 60_000L);

        var key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        var now = new Date();
        var notExpired = new Date(now.getTime() + 60_000L);

        var token = Jwts.builder()
                .claim("userId", "not-a-number")
                .subject("a@b.com")
                .issuedAt(now)
                .expiration(notExpired)
                .signWith(key)
                .compact();

        assertNull(sut.getUserIdFromExpiredToken(token));
    }

    private static void setField(Object target, String fieldName, Object value) throws Exception {
        Field f = target.getClass().getDeclaredField(fieldName);
        f.setAccessible(true);
        f.set(target, value);
    }
}
