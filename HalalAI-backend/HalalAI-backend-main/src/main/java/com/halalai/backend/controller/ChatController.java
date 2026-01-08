package com.halalai.backend.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.halalai.backend.dto.ChatRequest;
import com.halalai.backend.dto.ChatResponse;
import com.halalai.backend.dto.ConfigResponse;
import com.halalai.backend.service.LLMService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api")
public class ChatController {

    private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

    private final LLMService llmService;

    public ChatController(LLMService llmService) {
        this.llmService = llmService;
    }

    @PostMapping("/chat")
    public ChatResponse createChatCompletion(@RequestBody ChatRequest request) {
        logger.info("POST /api/chat - сообщений: {}, maxTokens: {}", 
                request.messages() != null ? request.messages().size() : 0, 
                request.maxTokens());

        return llmService.generateCompletion(
                request.messages(),
                request.apiKey(),
                request.remoteModel(),
                request.maxTokens());
    }

    @GetMapping(value = "/models", produces = MediaType.APPLICATION_JSON_VALUE + ";charset=UTF-8")
    public Map<String, Object> listModels() {
        return llmService.fetchModels();
    }
}

