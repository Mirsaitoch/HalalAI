package com.halalai.backend.dto;

import java.time.LocalDateTime;

public record ErrorResponse(
        String message,
        LocalDateTime timestamp,
        String path
) {
    public static ErrorResponse of(String message, String path) {
        return new ErrorResponse(message, LocalDateTime.now(), path);
    }
}

