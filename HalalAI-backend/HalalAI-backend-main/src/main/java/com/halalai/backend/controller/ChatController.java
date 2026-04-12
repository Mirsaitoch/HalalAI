package com.halalai.backend.controller;

import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.halalai.backend.dto.ChatRequest;
import com.halalai.backend.dto.ChatResponse;
import com.halalai.backend.service.IConfigService;
import com.halalai.backend.service.ILLMService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api")
public class ChatController {

    private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

    private final ILLMService llmService;
    private final IConfigService configService;

    public ChatController(ILLMService llmService, IConfigService configService) {
        this.llmService = llmService;
        this.configService = configService;
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
        logger.info("GET /api/models");
        return configService.getAvailableModels();
    }
}

