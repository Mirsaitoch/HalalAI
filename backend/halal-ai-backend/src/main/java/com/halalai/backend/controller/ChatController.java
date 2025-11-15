package com.halalai.backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.halalai.backend.dto.ChatRequest;
import com.halalai.backend.dto.ChatResponse;
import com.halalai.backend.service.ChatHistoryService;
import com.halalai.backend.service.LLMService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/api")
public class ChatController {

    private final LLMService llmService;
    private final ChatHistoryService chatHistoryService;

    public ChatController(LLMService llmService, ChatHistoryService chatHistoryService) {
        this.llmService = llmService;
        this.chatHistoryService = chatHistoryService;
    }

    @PostMapping("/chat")
    public ChatResponse createChatCompletion(@RequestBody ChatRequest request, HttpServletRequest httpRequest) {
        // Получаем или создаем HTTP сессию
        HttpSession session = httpRequest.getSession(true);
        return llmService.generateCompletion(request.prompt(), session);
    }

    /**
     * Очищает историю разговора для текущей HTTP сессии
     */
    @DeleteMapping("/chat/history")
    public ResponseEntity<Map<String, String>> clearHistory(HttpServletRequest httpRequest) {
        HttpSession session = httpRequest.getSession(false);
        if (session != null) {
            chatHistoryService.clearHistory(session);
            return ResponseEntity.ok(Map.of("status", "success", "message", "История очищена для текущей сессии"));
        }
        return ResponseEntity.ok(Map.of("status", "success", "message", "Сессия не найдена"));
    }
}

