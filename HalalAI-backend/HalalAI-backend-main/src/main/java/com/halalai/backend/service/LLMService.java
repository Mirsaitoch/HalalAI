package com.halalai.backend.service;

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
public class LLMService implements ILLMService {

    private static final Logger logger = LoggerFactory.getLogger(LLMService.class);

    private final RestTemplate restTemplate;
    private final String llmServiceUrl;
    private final int defaultMaxTokens;
    private final String systemPrompt;
    private final String defaultModel;
    private final List<String> allowedModels;

    public LLMService(
            RestTemplate restTemplate,
            @Value("${llm.service.url}") String llmServiceUrl,
            @Value("${llm.service.max-tokens:256}") int maxTokens,
            @Value("${llm.system.prompt}") String systemPrompt,
            @Value("${llm.models.default}") String defaultModel,
            @Value("${llm.models.allowed}") String allowedModelsStr) {
        this.restTemplate = restTemplate;
        this.llmServiceUrl = llmServiceUrl;
        this.defaultMaxTokens = maxTokens;
        this.systemPrompt = systemPrompt;
        this.defaultModel = defaultModel;
        this.allowedModels = List.of(allowedModelsStr.split(","));

        logger.info("Инициализация LLM Service... URL: {}", llmServiceUrl);
        logger.info("Доступные модели: default={}, count={}", defaultModel, this.allowedModels.size());
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
        String chatUrl = llmServiceUrl + "/llm/chat";

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
            Boolean usedRemote = responseBody.has("used_remote") ? responseBody.get("used_remote").asBoolean(false) : Boolean.FALSE;
            String remoteError = null;
            if (responseBody.has("remote_error") && !responseBody.get("remote_error").isNull()) {
                String error = responseBody.get("remote_error").asText("");
                remoteError = error.isEmpty() ? null : error;
            }

            if (reply.isEmpty()) {
                throw new RuntimeException("Ответ не содержит поле 'reply' или оно пустое. Структура: " + responseBody);
            }

            logger.info("Ответ от LLM получен: длина={} символов, remote={}",
                    reply.length(), usedRemote);

            return new ChatResponse(reply, usedRemote, remoteError);
            
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

}
