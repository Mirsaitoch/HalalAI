package com.halalai.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "Email не может быть пустым")
        @Email(message = "Email должен быть валидным")
        String email,

        @NotBlank(message = "Пароль не может быть пустым")
        String password
) {
}
