package com.halalai.backend.dto;

import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;

public record ChatRequest(
    String prompt,  // Для обратной совместимости
    List<Map<String, String>> messages,  // История сообщений от клиента
    @JsonProperty("api_key") String apiKey,
    @JsonProperty("remote_model") String remoteModel,
    @JsonProperty("max_tokens") Integer maxTokens
) {
}

