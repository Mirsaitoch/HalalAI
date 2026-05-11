package com.halalai.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.halalai.backend.dto.ChatRequest;
import com.halalai.backend.dto.ChatResponse;
import com.halalai.backend.service.IConfigService;
import com.halalai.backend.service.ILLMService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import com.halalai.backend.security.JwtAuthenticationFilter;

import java.util.List;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = ChatController.class)
@Import(com.halalai.backend.exception.GlobalExceptionHandler.class)
@AutoConfigureMockMvc(addFilters = false)
class ChatControllerWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ILLMService llmService;

    @MockBean
    private IConfigService configService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    void chat_success_delegatesToServiceAndReturnsResponse() throws Exception {
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenReturn(new ChatResponse("Ответ", true, null));

        var req = new ChatRequest(
                List.of(Map.of("role", "user", "content", "Привет")),
                "api-key",
                "remote-model",
                512,
                0.7,
                true
        );

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.reply").value("Ответ"))
                .andExpect(jsonPath("$.used_remote").value(true))
                .andExpect(jsonPath("$.remote_error").doesNotExist());
    }

    @Test
    void chat_nullMessages_stillReturnsOk_whenServiceHandlesIt() throws Exception {
        when(llmService.generateCompletion(isNull(), any(), any(), any(), any(), any()))
                .thenReturn(new ChatResponse("OK", false, null));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"messages\":null}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("OK"));
    }

    @Test
    void models_returnsMapFromConfigService() throws Exception {
        when(configService.getAvailableModels()).thenReturn(Map.of(
                "default_model", "m1",
                "allowed_models", List.of("m1", "m2")
        ));

        mockMvc.perform(get("/api/models"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.default_model").value("m1"))
                .andExpect(jsonPath("$.allowed_models", hasSize(2)));
    }
}

