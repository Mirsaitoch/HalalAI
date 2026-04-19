package com.halalai.backend.dto;

public record AuthResponse(
        String token,
        String type,
        Long userId,
        String email
) {
    public static AuthResponse of(String token, Long userId, String email) {
        return new AuthResponse(token, "Bearer", userId, email);
    }
}
