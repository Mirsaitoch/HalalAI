package com.halalai.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record RefreshTokenRequest(
        @NotBlank(message = "Токен не может быть пустым")
        String token
) {
}

