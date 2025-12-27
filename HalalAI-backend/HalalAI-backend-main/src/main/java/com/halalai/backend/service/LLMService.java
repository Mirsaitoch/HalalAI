package com.halalai.backend.service;

import java.util.ArrayList;
import java.util.HashMap;
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
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.JsonNode;
import com.halalai.backend.dto.ChatResponse;

@Service
public class LLMService {

    private final RestTemplate restTemplate;
    private final String llmServiceUrl;
    private final int defaultMaxTokens;

    public LLMService(
            RestTemplate restTemplate,
            @Value("${llm.service.url:http://localhost:8000}") String llmServiceUrl,
            @Value("${llm.service.max-tokens:1024}") int maxTokens) {
        this.restTemplate = restTemplate;
        this.llmServiceUrl = llmServiceUrl;
        this.defaultMaxTokens = maxTokens;
        
        System.out.println("Инициализация LLM Service...");
        System.out.println("URL: " + llmServiceUrl);
    }

    public ChatResponse generateCompletion(List<Map<String, String>> clientMessages, String prompt, String apiKey, String remoteModel, Integer maxTokensOverride) {
        System.out.println("\n========== ЗАПРОС К LLM СЕРВИСУ ==========");
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Accept-Charset", "UTF-8");

        // Формируем запрос к Python LLM сервису
        List<Map<String, String>> messages = new ArrayList<>();
        
        // Если клиент отправил историю, используем её
        if (clientMessages != null && !clientMessages.isEmpty()) {
            messages.addAll(clientMessages);
            System.out.println("Получена история от клиента: " + clientMessages.size() + " сообщений");
        } else if (prompt != null) {
            String systemPrompt = "Ты — HalalAI, умный исламский ассистент, специализирующийся на вопросах об Исламе и религии, исламских принципах, Коране и исламском образе жизни. Твоя задача — давать точные, полезные и основанные на исламских источниках ответы. Всегда отвечай на русском языке, используй исламские термины (халяль, харам, сунна и т.д.) и будь уважительным и терпеливым. Если вопрос не связан с исламом, вежливо направь разговор в нужное русло. Отвечай кратко, но информативно!!!";;
            messages.add(Map.of("role", "system", "content", systemPrompt));
            messages.add(Map.of("role", "user", "content", prompt));
            System.out.println("Используется простой prompt (обратная совместимость)");
        } else {
            throw new RuntimeException("Не указаны ни messages, ни prompt");
        }
        
        // Системный промпт должен приходить от клиента в первом сообщении
        // Если его нет - это ошибка конфигурации клиента, но не критично
        boolean hasSystem = messages.stream().anyMatch(msg -> "system".equals(msg.get("role")));
        if (!hasSystem) {
            System.out.println("⚠️  Внимание: системный промпт отсутствует в истории от клиента");
        }
        
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("messages", messages);
        // используем max_tokens из клиента, если передан, иначе дефолт из настроек
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
            System.out.println("Отправка запроса к LLM сервису: " + chatUrl);
            System.out.println("Тело запроса: messages=" + messages.size() + ", max_tokens=" + effectiveMaxTokens
                    + (requestBody.containsKey("api_key") ? ", api_key=***" : "")
                    + (requestBody.containsKey("remote_model") ? ", remote_model=" + requestBody.get("remote_model") : ""));
            for (int i = 0; i < messages.size(); i++) {
                Map<String, String> msg = messages.get(i);
                String content = msg.get("content");
                String preview = content != null && content.length() > 100 ? content.substring(0, 100) + "..." : content;
                // Выводим только первые 50 символов для системного промпта, чтобы не засорять логи
                if ("system".equals(msg.get("role")) && content != null && content.length() > 50) {
                    preview = content.substring(0, 50) + "... (системный промпт, обрезан)";
                }
                System.out.println("  Message " + i + ": role=" + msg.get("role") + ", content=" + preview);
            }
            
            ResponseEntity<JsonNode> responseEntity = restTemplate.exchange(
                    chatUrl,
                    HttpMethod.POST,
                    requestEntity,
                    JsonNode.class
            );
            
            System.out.println("Получен ответ от LLM сервиса. Статус: " + responseEntity.getStatusCode());

            JsonNode responseBody = responseEntity.getBody();
            
            if (responseBody == null) {
                throw new RuntimeException("LLM сервис вернул пустой ответ");
            }
            
            // Извлекаем ответ из поля "reply"
            String reply = responseBody.has("reply") ? responseBody.get("reply").asText("") : "";
            if (reply == null) reply = "";
            String model = responseBody.has("model") ? responseBody.get("model").asText("") : "";
            Boolean usedRemote = responseBody.has("used_remote") ? responseBody.get("used_remote").asBoolean(false) : Boolean.FALSE;
            String remoteError = responseBody.has("remote_error") ? responseBody.get("remote_error").asText("") : "";
            if (reply.isEmpty()) {
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
            System.err.println("========== ОШИБКА HTTP ==========");
            System.err.println("Статус: " + e.getStatusCode());
            System.err.println("Тело ответа: " + e.getResponseBodyAsString());
            System.err.println("URL: " + chatUrl);
            e.printStackTrace();
            
            if (e.getStatusCode().value() == 503) {
                throw new RuntimeException("LLM сервис не готов. Убедитесь, что Python сервис запущен и модель загружена.", e);
            }
            
            throw new ResponseStatusException(e.getStatusCode(), "Ошибка LLM сервиса: " + e.getResponseBodyAsString(), e);
            
        } catch (org.springframework.web.client.ResourceAccessException e) {
            System.err.println("========== ОШИБКА ПОДКЛЮЧЕНИЯ ==========");
            System.err.println("Не удалось подключиться к LLM сервису: " + e.getMessage());
            System.err.println("URL: " + chatUrl);
            System.err.println("Проверьте, что Python сервис запущен на " + llmServiceUrl);
            e.printStackTrace();
            throw new RuntimeException("Не удалось подключиться к LLM сервису по адресу " + chatUrl + ". " +
                    "Убедитесь, что Python сервис запущен на " + llmServiceUrl, e);
            
        } catch (RestClientException e) {
            System.err.println("========== ОШИБКА REST CLIENT ==========");
            System.err.println("Ошибка: " + e.getMessage());
            System.err.println("URL: " + chatUrl);
            e.printStackTrace();
            throw new RuntimeException("Не удалось подключиться к LLM сервису по адресу " + chatUrl + ". " +
                    "Убедитесь, что Python сервис запущен на " + llmServiceUrl, e);
        } catch (Exception e) {
            System.err.println("========== НЕИЗВЕСТНАЯ ОШИБКА ==========");
            System.err.println("Ошибка при генерации ответа: " + e.getMessage());
            e.printStackTrace();
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
