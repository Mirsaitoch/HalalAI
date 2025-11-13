package com.halalai.backend.service;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.JsonNode;
import com.halalai.backend.dto.ChatResponse;

@Service
public class OpenRouterService {

    private final RestTemplate restTemplate;
    private final String apiKey;
    private final String apiUrl;
    private final String model;
    private final String referer;
    private final String title;
    private final int maxTokens;

    public OpenRouterService(
            RestTemplate restTemplate,
            @Value("${chat.api.key:}") String apiKey,
            @Value("${chat.api.base-url}") String apiUrl,
            @Value("${chat.api.model:openrouter/auto}") String model,
            @Value("${chat.api.referer:}") String referer,
            @Value("${chat.api.title:HalalAI Backend}") String title,
            @Value("${chat.api.max-tokens:512}") int maxTokens) {
        this.restTemplate = restTemplate;
        this.apiKey = apiKey;
        this.apiUrl = apiUrl;
        this.model = model;
        this.referer = referer;
        this.title = title;
        this.maxTokens = maxTokens;
    }

    public ChatResponse generateCompletion(String prompt) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("OpenRouter API key is not configured. Set environment variable OPENROUTER_API_KEY.");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);
        if (!referer.isBlank()) {
            headers.add("HTTP-Referer", referer);
        }
        if (!title.isBlank()) {
            headers.add("X-Title", title);
        }

        Map<String, Object> requestBody = Map.of(
                "model", model,
                "messages", List.of(
                        Map.of(
                                "role", "user",
                                "content", prompt
                        )
                ),
                "max_tokens", maxTokens
        );

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);

        try {
            ResponseEntity<JsonNode> responseEntity = restTemplate.exchange(
                    apiUrl,
                    HttpMethod.POST,
                    requestEntity,
                    JsonNode.class
            );

            JsonNode responseBody = responseEntity.getBody();
            String reply = extractFirstMessage(responseBody);

            return new ChatResponse(reply);
        } catch (HttpClientErrorException e) {
            throw new ResponseStatusException(e.getStatusCode(), e.getResponseBodyAsString(), e);
        }
    }

    private String extractFirstMessage(JsonNode responseBody) {
        if (responseBody == null) {
            return "";
        }

        JsonNode choices = responseBody.path("choices");
        if (choices.isArray() && choices.size() > 0) {
            JsonNode firstChoice = choices.get(0);
            JsonNode message = firstChoice.path("message");
            if (message.has("content")) {
                return message.path("content").asText("");
            }
        }
        return "";
    }
}

