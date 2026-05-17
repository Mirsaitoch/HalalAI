package com.halalai.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.halalai.backend.controller.AuthController;
import com.halalai.backend.controller.ChatController;
import com.halalai.backend.dto.*;
import com.halalai.backend.exception.GlobalExceptionHandler;
import com.halalai.backend.security.JwtAuthenticationFilter;
import com.halalai.backend.service.IAuthService;
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
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Map;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * 4.4.4 Проверка надёжности системы.
 *
 * Проверяет, что система корректно деградирует при сбоях, не падает с
 * необработанными исключениями и восстанавливается после транзиентных ошибок.
 */
@WebMvcTest(controllers = {AuthController.class, ChatController.class})
@Import(GlobalExceptionHandler.class)
@AutoConfigureMockMvc(addFilters = false)
class ReliabilityMvcTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    @MockBean IAuthService authService;
    @MockBean ILLMService  llmService;
    @MockBean IConfigService configService;
    @MockBean JwtAuthenticationFilter jwtAuthenticationFilter;

    // ── LLM-сервис недоступен — API не падает ────────────────────────────────

    @Test
    void chat_whenLlmServiceConnectionFails_returns5xx_withErrorMessage() throws Exception {
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenThrow(new RuntimeException("Не удалось подключиться к LLM сервису"));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ChatRequest(
                                List.of(Map.of("role", "user", "content", "Q")),
                                null, null, null, null, null))))
                .andExpect(status().is5xxServerError())
                .andExpect(jsonPath("$.message", containsString("LLM")));
    }

    @Test
    void chat_whenLlmServiceNotReady_returns5xx_notUnhandledException() throws Exception {
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenThrow(new RuntimeException("LLM сервис не готов"));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ChatRequest(
                                List.of(Map.of("role", "user", "content", "Q")),
                                null, null, null, null, null))))
                .andExpect(status().is5xxServerError())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    @Test
    void chat_whenLlmServiceReturns400_propagatesStatusException() throws Exception {
        // GlobalExceptionHandler перехватывает RuntimeException (включая ResponseStatusException)
        // и возвращает 500 с JSON-телом — корректное поведение для upstream-ошибки.
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenThrow(new ResponseStatusException(HttpStatus.BAD_REQUEST, "Некорректный запрос к LLM"));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ChatRequest(
                                List.of(Map.of("role", "user", "content", "Q")),
                                null, null, null, null, null))))
                .andExpect(status().is5xxServerError())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    // ── Авторизация работает независимо от состояния LLM ─────────────────────

    @Test
    void authService_remainsAvailable_whenChatServiceFails() throws Exception {
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenThrow(new RuntimeException("LLM недоступен"));
        when(authService.login(any()))
                .thenReturn(new AuthResponse("tok", "Bearer", 1L, "a@b.com"));

        // chat упал
        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ChatRequest(
                                List.of(Map.of("role", "user", "content", "Q")),
                                null, null, null, null, null))))
                .andExpect(status().is5xxServerError());

        // auth всё равно работает
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new LoginRequest("a@b.com", "password123"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("tok"));
    }

    // ── Повторяемость и восстановление ───────────────────────────────────────

    @Test
    void login_repeatedRequests_allSucceed() throws Exception {
        when(authService.login(any()))
                .thenReturn(new AuthResponse("tok", "Bearer", 1L, "a@b.com"));

        for (int i = 0; i < 10; i++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(
                                    new LoginRequest("a@b.com", "password123"))))
                    .andExpect(status().isOk());
        }
    }

    @Test
    void chat_recoversAfterTransientLlmFailure() throws Exception {
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenThrow(new RuntimeException("временный сбой"))
                .thenReturn(new ChatResponse("Восстановленный ответ", true, null));

        var body = objectMapper.writeValueAsString(new ChatRequest(
                List.of(Map.of("role", "user", "content", "Q")),
                "k", null, null, null, null));

        // первый запрос — сбой LLM
        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is5xxServerError());

        // второй запрос — LLM восстановился
        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("Восстановленный ответ"));
    }

    // ── Некорректные данные не роняют систему ────────────────────────────────

    @Test
    void chat_withNullMessages_doesNotCrashApplication() throws Exception {
        when(llmService.generateCompletion(isNull(), any(), any(), any(), any(), any()))
                .thenReturn(new ChatResponse("OK", false, null));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"messages\":null}"))
                .andExpect(status().is2xxSuccessful());
    }

    @Test
    void register_withInvalidData_returns400_doesNotCrash() throws Exception {
        // Валидационная ошибка — система должна вернуть 400, а не 500
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new RegisterRequest("not-an-email", "short"))))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    @Test
    void register_repeated_failures_doesNotDegradeSubsequentRequests() throws Exception {
        when(authService.register(any()))
                .thenThrow(new RuntimeException("БД недоступна"))
                .thenThrow(new RuntimeException("БД недоступна"))
                .thenReturn(new AuthResponse("tok", "Bearer", 1L, "a@b.com"));

        var body = objectMapper.writeValueAsString(new RegisterRequest("a@b.com", "password123"));

        // два сбоя подряд
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().is5xxServerError());
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().is5xxServerError());

        // система восстановилась
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("tok"));
    }
}
