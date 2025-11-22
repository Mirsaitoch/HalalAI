package com.halalai.backend.controller;

import java.nio.charset.StandardCharsets;
import java.util.Properties;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.springframework.core.io.ClassPathResource;
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

@RestController
@RequestMapping("/api")
public class ChatController {

    private final LLMService llmService;
    private final String systemPrompt;

    public ChatController(LLMService llmService) {
        this.llmService = llmService;
        // Читаем системный промпт из properties файла с правильной кодировкой UTF-8
        this.systemPrompt = loadSystemPrompt();
    }
    
    private String loadSystemPrompt() {
        try {
            ClassPathResource resource = new ClassPathResource("application.properties");
            Properties props = new Properties();
            try (InputStream inputStream = resource.getInputStream();
                 InputStreamReader reader = new InputStreamReader(inputStream, StandardCharsets.UTF_8)) {
                props.load(reader);
            }
            String prompt = props.getProperty("llm.system.prompt");
            if (prompt != null && !prompt.isEmpty()) {
                return prompt;
            }
        } catch (Exception e) {
            System.err.println("Ошибка при загрузке системного промпта: " + e.getMessage());
        }
        // Fallback на дефолтное значение
        return "Ты — HalalAI, умный исламский ассистент, специализирующийся на вопросах об Исламе и религии, исламских принципах, Коране и исламском образе жизни. Твоя задача — давать точные, полезные и основанные на исламских источниках ответы. Всегда отвечай на русском языке, используй исламские термины (халяль, харам, сунна и т.д.) и будь уважительным и терпеливым. Если вопрос не связан с исламом, вежливо направь разговор в нужное русло. Отвечай кратко, но информативно!!!";
    }

    @GetMapping(value = "/config", produces = MediaType.APPLICATION_JSON_VALUE + ";charset=UTF-8")
    public ConfigResponse getConfig() {
        return new ConfigResponse(systemPrompt);
    }

    @PostMapping("/chat")
    public ChatResponse createChatCompletion(@RequestBody ChatRequest request) {
        // История теперь приходит от клиента, не используем сессию для хранения
        return llmService.generateCompletion(request.messages(), request.prompt());
    }
}

