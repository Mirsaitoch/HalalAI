package com.halalai.backend.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Component
public class JwtTokenProvider {

    private static final Logger logger = LoggerFactory.getLogger(JwtTokenProvider.class);

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private Long expiration;

    private SecretKey getSigningKey() {
        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(String username, Long userId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        return createToken(claims, username);
    }

    private String createToken(Map<String, Object> claims, String subject) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration);

        return Jwts.builder()
                .claims(claims)
                .subject(subject)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    /**
     * Извлекает username из токена, даже если он истек (для refresh)
     */
    public String getUsernameFromExpiredToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return claims.getSubject();
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            return e.getClaims().getSubject();
        } catch (Exception e) {
            logger.error("Ошибка при извлечении username из истекшего токена: {}", e.getMessage(), e);
            throw e;
        }
    }

    /**
     * Извлекает userId из токена, даже если он истек (для refresh)
     */
    public Long getUserIdFromExpiredToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            Object userId = claims.get("userId");
            if (userId instanceof Number) {
                return ((Number) userId).longValue();
            }
            return null;
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            // Для истекших токенов все равно извлекаем userId
            Object userId = e.getClaims().get("userId");
            if (userId instanceof Number) {
                return ((Number) userId).longValue();
            }
            return null;
        } catch (Exception e) {
            logger.error("Ошибка при извлечении userId из истекшего токена: " + e.getMessage(), e);
            return null;
        }
    }

    public <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = getAllClaimsFromToken(token);
        return claimsResolver.apply(claims);
    }

    private Claims getAllClaimsFromToken(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            logger.debug("JWT токен истек");
            throw e;
        } catch (io.jsonwebtoken.security.SignatureException e) {
            logger.error("Неверная подпись JWT токена", e);
            throw e;
        } catch (io.jsonwebtoken.MalformedJwtException e) {
            logger.error("Некорректный формат JWT токена", e);
            throw e;
        } catch (Exception e) {
            logger.error("Ошибка при парсинге JWT токена", e);
            throw e;
        }
    }

    public Boolean isTokenExpired(String token) {
        try {
            Claims claims = getAllClaimsFromToken(token);
            Date expiration = claims.getExpiration();
            return expiration.before(new Date());
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            // Если токен истек, возвращаем true
            return true;
        } catch (Exception e) {
            logger.debug("Ошибка при проверке истечения токена: {}", e.getMessage());
            return true;
        }
    }

    public Boolean validateToken(String token, UserDetails userDetails) {
        try {
            final String username = getUsernameFromToken(token);
            boolean isExpired = isTokenExpired(token);
            boolean usernameMatches = username.equals(userDetails.getUsername());
            
            return usernameMatches && !isExpired;
        } catch (Exception e) {
            logger.debug("Ошибка при валидации токена: {}", e.getMessage());
            return false;
        }
    }
}

