package com.halalai.backend.service;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.JsonNode;
import com.halalai.backend.dto.ChatResponse;

@Service
public class OpenRouterService {

    private final RestTemplate restTemplate;
    private final String llmServiceUrl;
    private final int maxTokens;

    public OpenRouterService(
            RestTemplate restTemplate,
            @Value("${llm.service.url:http://localhost:8000}") String llmServiceUrl,
            @Value("${llm.service.max-tokens:1024}") int maxTokens) {
        this.restTemplate = restTemplate;
        this.llmServiceUrl = llmServiceUrl;
        this.maxTokens = maxTokens;
        
        System.out.println("Инициализация LLM Service...");
        System.out.println("URL: " + llmServiceUrl);
    }

    public ChatResponse generateCompletion(String prompt) {
        System.out.println("\n========== ЗАПРОС К LLM СЕРВИСУ ==========");
        System.out.println("Запрос пользователя: " + prompt);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        // Формируем запрос к Python LLM сервису
        Map<String, Object> requestBody = Map.of(
                "prompt", prompt,
                "max_tokens", maxTokens
        );

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
        String chatUrl = llmServiceUrl + "/chat";

        try {
            System.out.println("Отправка запроса к LLM сервису: " + chatUrl);
            ResponseEntity<JsonNode> responseEntity = restTemplate.exchange(
                    chatUrl,
                    HttpMethod.POST,
                    requestEntity,
                    JsonNode.class
            );

            JsonNode responseBody = responseEntity.getBody();
            
            if (responseBody == null) {
                throw new RuntimeException("LLM сервис вернул пустой ответ");
            }
            
            // Извлекаем ответ из поля "reply"
            String reply = responseBody.has("reply") ? responseBody.get("reply").asText("") : "";
            String model = responseBody.has("model") ? responseBody.get("model").asText("") : "";
            Boolean usedRemote = responseBody.has("used_remote") ? responseBody.get("used_remote").asBoolean(false) : Boolean.FALSE;
            String remoteError = responseBody.has("remote_error") ? responseBody.get("remote_error").asText("") : "";
            if (reply == null || reply.isEmpty()) {
                throw new RuntimeException("Ответ не содержит поле 'reply' или оно пустое. Структура: " + responseBody.toString());
            }
            
            System.out.println("========== ОТВЕТ ОТ LLM ==========");
            System.out.println("Длина ответа: " + reply.length() + " символов");
            if (!reply.isEmpty()) {
                System.out.println("Первые 300 символов ответа:");
                System.out.println(reply.substring(0, Math.min(300, reply.length())));
                if (reply.length() > 300) {
                    System.out.println("... (ответ обрезан для логов)");
                }
            } else {
                System.out.println("⚠️  Ответ пустой!");
            }
            System.out.println("========== КОНЕЦ ОТВЕТА ==========\n");

            return new ChatResponse(reply, model, usedRemote, remoteError);
            
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            System.err.println("Ошибка HTTP при запросе к LLM сервису: " + e.getStatusCode() + " - " + e.getResponseBodyAsString());
            
            if (e.getStatusCode().value() == 503) {
                throw new RuntimeException("LLM сервис не готов. Убедитесь, что Python сервис запущен и модель загружена.", e);
            }
            
            throw new ResponseStatusException(e.getStatusCode(), "Ошибка LLM сервиса: " + e.getResponseBodyAsString(), e);
            
        } catch (RestClientException e) {
            System.err.println("Ошибка подключения к LLM сервису: " + e.getMessage());
            throw new RuntimeException("Не удалось подключиться к LLM сервису по адресу " + chatUrl + ". " +
                    "Убедитесь, что Python сервис запущен на " + llmServiceUrl, e);
        } catch (Exception e) {
            System.err.println("Ошибка при генерации ответа: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Ошибка при генерации ответа: " + e.getMessage(), e);
        }
    }
}
