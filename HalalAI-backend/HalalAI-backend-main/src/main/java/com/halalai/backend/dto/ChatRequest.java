package com.halalai.backend.dto;

import java.util.List;
import java.util.Map;

public record ChatRequest(
    String prompt,  // Для обратной совместимости
    List<Map<String, String>> messages  // История сообщений от клиента
) {
}

