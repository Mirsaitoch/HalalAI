package com.halalai.backend.service;

import java.util.ArrayList;
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
import com.halalai.backend.model.ChatMessage;

@Service
public class LLMService {

    private final RestTemplate restTemplate;
    private final ChatHistoryService chatHistoryService;
    private final String llmServiceUrl;
    private final int maxTokens;

    public LLMService(
            RestTemplate restTemplate,
            ChatHistoryService chatHistoryService,
            @Value("${llm.service.url:http://localhost:8000}") String llmServiceUrl,
            @Value("${llm.service.max-tokens:1024}") int maxTokens) {
        this.restTemplate = restTemplate;
        this.chatHistoryService = chatHistoryService;
        this.llmServiceUrl = llmServiceUrl;
        this.maxTokens = maxTokens;
        
        System.out.println("Инициализация LLM Service...");
        System.out.println("URL: " + llmServiceUrl);
    }

    public ChatResponse generateCompletion(String prompt, jakarta.servlet.http.HttpSession session) {
        System.out.println("\n========== ЗАПРОС К LLM СЕРВИСУ ==========");
        System.out.println("Запрос пользователя: " + prompt);
        System.out.println("Session ID: " + (session != null ? session.getId() : "не создана"));
        
        // Получаем историю разговора (без текущего запроса)
        List<ChatMessage> history = chatHistoryService.getHistory(session);
        System.out.println("История разговора: " + history.size() + " сообщений");
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        // Формируем запрос к Python LLM сервису с историей
        List<Map<String, String>> messages = new ArrayList<>();
        
        // Добавляем историю сообщений
        for (ChatMessage msg : history) {
            messages.add(Map.of("role", msg.role(), "content", msg.content()));
        }
        
        // Добавляем текущий запрос пользователя
        messages.add(Map.of("role", "user", "content", prompt));
        
        // Сохраняем запрос пользователя в историю (после формирования messages)
        chatHistoryService.addUserMessage(session, prompt);
        
        Map<String, Object> requestBody = Map.of(
                "messages", messages,
                "max_tokens", maxTokens
        );

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
        String chatUrl = llmServiceUrl + "/chat";

        try {
            System.out.println("Отправка запроса к LLM сервису: " + chatUrl);
            System.out.println("Тело запроса: messages=" + messages.size() + ", max_tokens=" + maxTokens);
            for (int i = 0; i < messages.size(); i++) {
                Map<String, String> msg = messages.get(i);
                System.out.println("  Message " + i + ": role=" + msg.get("role") + ", content=" + 
                    (msg.get("content").length() > 100 ? msg.get("content").substring(0, 100) + "..." : msg.get("content")));
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
            String reply = "";
            if (responseBody.has("reply")) {
                reply = responseBody.get("reply").asText("");
            } else {
                throw new RuntimeException("Ответ не содержит поле 'reply'. Структура: " + responseBody.toString());
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

            // Сохраняем ответ ассистента в историю
            chatHistoryService.addAssistantMessage(session, reply);

            return new ChatResponse(reply);
            
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

}
