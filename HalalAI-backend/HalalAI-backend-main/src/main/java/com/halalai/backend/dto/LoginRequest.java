package com.halalai.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "Имя пользователя или email не может быть пустым")
        String usernameOrEmail,

        @NotBlank(message = "Пароль не может быть пустым")
        String password
) {
}

