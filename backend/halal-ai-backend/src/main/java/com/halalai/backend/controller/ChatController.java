package com.halalai.backend.controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.halalai.backend.dto.ChatRequest;
import com.halalai.backend.dto.ChatResponse;
import com.halalai.backend.service.OpenRouterService;

@RestController
@RequestMapping("/api")
public class ChatController {

    private final OpenRouterService openRouterService;

    public ChatController(OpenRouterService openRouterService) {
        this.openRouterService = openRouterService;
    }

    @PostMapping("/chat")
    public ChatResponse createChatCompletion(@RequestBody ChatRequest request) {
        return openRouterService.generateCompletion(request.prompt());
    }
}

