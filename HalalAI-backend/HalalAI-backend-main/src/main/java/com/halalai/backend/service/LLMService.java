package com.halalai.backend.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
public class LLMService {

    private static final Logger logger = LoggerFactory.getLogger(LLMService.class);

    private final RestTemplate restTemplate;
    private final String llmServiceUrl;
    private final int defaultMaxTokens;
    private final String systemPrompt;

    public LLMService(
            RestTemplate restTemplate,
            @Value("${llm.service.url}") String llmServiceUrl,
            @Value("${llm.service.max-tokens:256}") int maxTokens,
            @Value("${llm.system.prompt}") String systemPrompt) {
        this.restTemplate = restTemplate;
        this.llmServiceUrl = llmServiceUrl;
        this.defaultMaxTokens = maxTokens;
        this.systemPrompt = systemPrompt;
        
        logger.info("Инициализация LLM Service... URL: {}", llmServiceUrl);
    }

    public ChatResponse generateCompletion(List<Map<String, String>> clientMessages, String apiKey, String remoteModel, Integer maxTokensOverride) {
        logger.debug("Запрос к LLM сервису");
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Accept-Charset", "UTF-8");

        List<Map<String, String>> messages;
        
        if (clientMessages != null && !clientMessages.isEmpty()) {
            messages = new ArrayList<>(clientMessages);
            logger.debug("Получена история от клиента: {} сообщений", clientMessages.size());
            messages.add(0, Map.of("role", "system", "content", systemPrompt));
            logger.debug("Добавлен системный промпт из конфигурации");
        } else {
            throw new IllegalArgumentException("Не указаны ни messages, ни prompt");
        }
        
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("messages", messages);

        int effectiveMaxTokens = maxTokensOverride != null ? maxTokensOverride : defaultMaxTokens;
        requestBody.put("max_tokens", effectiveMaxTokens);
        if (apiKey != null && !apiKey.isBlank()) {
            requestBody.put("api_key", apiKey.trim());
        }
        if (remoteModel != null && !remoteModel.isBlank()) {
            requestBody.put("remote_model", remoteModel.trim());
        }

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
        String chatUrl = llmServiceUrl + "/chat";

        try {
            logger.debug("Отправка запроса к LLM сервису: {}", chatUrl);
            logger.debug("Тело запроса: messages={}, max_tokens={}{}{}", 
                    messages.size(), 
                    effectiveMaxTokens,
                    requestBody.containsKey("api_key") ? ", api_key=***" : "",
                    requestBody.containsKey("remote_model") ? ", remote_model=" + requestBody.get("remote_model") : "");
            
            ResponseEntity<JsonNode> responseEntity = restTemplate.exchange(
                    chatUrl,
                    HttpMethod.POST,
                    requestEntity,
                    JsonNode.class
            );
            
            logger.debug("Получен ответ от LLM сервиса. Статус: {}", responseEntity.getStatusCode());

            JsonNode responseBody = responseEntity.getBody();
            if (responseBody == null) {
                throw new RuntimeException("LLM сервис вернул пустой ответ");
            }
            String reply = responseBody.has("reply") ? responseBody.get("reply").asText("") : "";
            String model = responseBody.has("model") ? responseBody.get("model").asText("") : "";
            Boolean usedRemote = responseBody.has("used_remote") ? responseBody.get("used_remote").asBoolean(false) : Boolean.FALSE;
            String remoteError = responseBody.has("remote_error") ? responseBody.get("remote_error").asText("") : null;
            
            if (reply.isEmpty()) {
                throw new RuntimeException("Ответ не содержит поле 'reply' или оно пустое. Структура: " + responseBody);
            }
            
            logger.info("Ответ от LLM получен: длина={} символов, модель={}, remote={}", 
                    reply.length(), model, usedRemote);

            return new ChatResponse(reply, model, usedRemote, remoteError);
            
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            logger.error("Ошибка HTTP при обращении к LLM сервису: статус={}, URL={}, тело={}", 
                    e.getStatusCode(), chatUrl, e.getResponseBodyAsString());
            
            if (e.getStatusCode().value() == 503) {
                throw new RuntimeException("LLM сервис не готов. Убедитесь, что Python сервис запущен и модель загружена.", e);
            }
            
            throw new ResponseStatusException(e.getStatusCode(), "Ошибка LLM сервиса: " + e.getResponseBodyAsString(), e);
            
        } catch (org.springframework.web.client.ResourceAccessException e) {
            logger.error("Ошибка подключения к LLM сервису: URL={}, сообщение={}", chatUrl, e.getMessage());
            throw new RuntimeException("Не удалось подключиться к LLM сервису по адресу " + chatUrl + ". " +
                    "Убедитесь, что Python сервис запущен на " + llmServiceUrl, e);
            
        } catch (RestClientException e) {
            logger.error("Ошибка REST клиента при обращении к LLM сервису: URL={}, сообщение={}", chatUrl, e.getMessage());
            throw new RuntimeException("Не удалось подключиться к LLM сервису по адресу " + chatUrl + ". " +
                    "Убедитесь, что Python сервис запущен на " + llmServiceUrl, e);
        } catch (Exception e) {
            logger.error("Неизвестная ошибка при генерации ответа: {}", e.getMessage(), e);
            throw new RuntimeException("Ошибка при генерации ответа: " + e.getMessage(), e);
        }
    }

    public Map<String, Object> fetchModels() {
        String url = llmServiceUrl + "/models";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Void> requestEntity = new HttpEntity<>(headers);
        try {
            ResponseEntity<JsonNode> response = restTemplate.exchange(url, HttpMethod.GET, requestEntity, JsonNode.class);
            if (response.getBody() == null) {
                throw new RuntimeException("Пустой ответ от /models");
            }
            Map<String, Object> result = new HashMap<>();
            JsonNode body = response.getBody();
            result.put("default_model", body.path("default_model").asText(""));
            if (body.has("allowed_models") && body.get("allowed_models").isArray()) {
                List<String> allowed = new ArrayList<>();
                body.get("allowed_models").forEach(node -> allowed.add(node.asText("")));
                result.put("allowed_models", allowed);
            } else {
                result.put("allowed_models", List.of());
            }
            return result;
        } catch (Exception e) {
            throw new RuntimeException("Не удалось получить список моделей: " + e.getMessage(), e);
        }
    }
}
