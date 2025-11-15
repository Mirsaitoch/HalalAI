package com.halalai.backend.model;

import java.time.LocalDateTime;

/**
 * Сообщение в истории разговора
 */
public record ChatMessage(
    String role,  // "user" или "assistant"
    String content,
    LocalDateTime timestamp
) {
}

