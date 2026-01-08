package com.halalai.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "Имя пользователя не может быть пустым")
        @Size(min = 2, max = 50, message = "Имя пользователя должно быть от 2 до 50 символов")
        String username,

        @NotBlank(message = "Email не может быть пустым")
        @Email(message = "Email должен быть валидным")
        String email,

        @NotBlank(message = "Пароль не может быть пустым")
        @Size(min = 8, message = "Пароль должен содержать минимум 8 символов")
        String password
) {
}

