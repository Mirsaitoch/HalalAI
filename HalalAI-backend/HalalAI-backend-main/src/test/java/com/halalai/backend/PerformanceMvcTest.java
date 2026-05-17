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

import java.util.List;
import java.util.Map;
import java.util.concurrent.*;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 4.4.3 Проверка производительности системы.
 *
 * Проверяет, что ключевые API-эндпоинты отвечают в рамках установленных SLA.
 * Запускается с замоканными сервисами (без реальной БД/LLM), поэтому SLA
 * распространяется на слой HTTP/MVC, а не на бизнес-логику.
 */
@WebMvcTest(controllers = {AuthController.class, ChatController.class})
@Import(GlobalExceptionHandler.class)
@AutoConfigureMockMvc(addFilters = false)
class PerformanceMvcTest {

    /** Максимальное время ответа для эндпоинтов аутентификации (мс). */
    private static final long AUTH_SLA_MS   = 500;
    /** Максимальное время ответа для чат-эндпоинта (мс). */
    private static final long CHAT_SLA_MS   = 2_000;
    /** Максимальное время ответа для справочных эндпоинтов (мс). */
    private static final long MODELS_SLA_MS = 200;

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    @MockBean IAuthService authService;
    @MockBean ILLMService  llmService;
    @MockBean IConfigService configService;
    @MockBean JwtAuthenticationFilter jwtAuthenticationFilter;

    // ── Одиночные запросы ─────────────────────────────────────────────────────

    @Test
    void register_respondsWithinSla() throws Exception {
        when(authService.register(any()))
                .thenReturn(new AuthResponse("tok", "Bearer", 1L, "a@b.com"));

        long start = System.currentTimeMillis();
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new RegisterRequest("a@b.com", "password123"))))
                .andExpect(status().isCreated());
        long elapsed = System.currentTimeMillis() - start;

        assertTrue(elapsed < AUTH_SLA_MS,
                "register превысил SLA: " + elapsed + " мс > " + AUTH_SLA_MS + " мс");
    }

    @Test
    void login_respondsWithinSla() throws Exception {
        when(authService.login(any()))
                .thenReturn(new AuthResponse("tok", "Bearer", 1L, "a@b.com"));

        long start = System.currentTimeMillis();
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new LoginRequest("a@b.com", "password123"))))
                .andExpect(status().isOk());
        long elapsed = System.currentTimeMillis() - start;

        assertTrue(elapsed < AUTH_SLA_MS,
                "login превысил SLA: " + elapsed + " мс > " + AUTH_SLA_MS + " мс");
    }

    @Test
    void refreshToken_respondsWithinSla() throws Exception {
        when(authService.refreshToken(anyString()))
                .thenReturn(new AuthResponse("new-tok", "Bearer", 1L, "a@b.com"));

        long start = System.currentTimeMillis();
        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new RefreshTokenRequest("old-tok"))))
                .andExpect(status().isOk());
        long elapsed = System.currentTimeMillis() - start;

        assertTrue(elapsed < AUTH_SLA_MS,
                "refresh превысил SLA: " + elapsed + " мс > " + AUTH_SLA_MS + " мс");
    }

    @Test
    void chat_respondsWithinSla() throws Exception {
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenReturn(new ChatResponse("Ответ", true, null));

        var req = new ChatRequest(
                List.of(Map.of("role", "user", "content", "Вопрос")),
                "api-key", "model", 512, 0.7, true);

        long start = System.currentTimeMillis();
        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
        long elapsed = System.currentTimeMillis() - start;

        assertTrue(elapsed < CHAT_SLA_MS,
                "chat превысил SLA: " + elapsed + " мс > " + CHAT_SLA_MS + " мс");
    }

    @Test
    void models_respondsWithinSla() throws Exception {
        when(configService.getAvailableModels())
                .thenReturn(Map.of("default", "m1", "allowed", List.of("m1", "m2")));

        long start = System.currentTimeMillis();
        mockMvc.perform(get("/api/models")).andExpect(status().isOk());
        long elapsed = System.currentTimeMillis() - start;

        assertTrue(elapsed < MODELS_SLA_MS,
                "models превысил SLA: " + elapsed + " мс > " + MODELS_SLA_MS + " мс");
    }

    // ── Параллельные запросы ──────────────────────────────────────────────────

    @Test
    void concurrentLoginRequests_allCompleteWithinGlobalTimeout() throws Exception {
        when(authService.login(any()))
                .thenReturn(new AuthResponse("tok", "Bearer", 1L, "a@b.com"));

        int threads = 5;
        var pool  = Executors.newFixedThreadPool(threads);
        var latch = new CountDownLatch(threads);

        long start = System.currentTimeMillis();
        for (int i = 0; i < threads; i++) {
            pool.submit(() -> {
                try {
                    mockMvc.perform(post("/api/auth/login")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content(objectMapper.writeValueAsString(
                                            new LoginRequest("a@b.com", "password123"))))
                            .andExpect(status().isOk());
                } catch (Exception e) {
                    throw new RuntimeException(e);
                } finally {
                    latch.countDown();
                }
            });
        }

        assertTrue(latch.await(5, TimeUnit.SECONDS),
                "Параллельные запросы не завершились за 5 секунд");
        long elapsed = System.currentTimeMillis() - start;
        pool.shutdown();

        assertTrue(elapsed < 5_000,
                "Параллельные запросы заняли слишком долго: " + elapsed + " мс");
    }

    @Test
    void concurrentChatRequests_allCompleteWithinGlobalTimeout() throws Exception {
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenReturn(new ChatResponse("Ответ", true, null));

        int threads = 5;
        var pool  = Executors.newFixedThreadPool(threads);
        var latch = new CountDownLatch(threads);
        var body  = objectMapper.writeValueAsString(new ChatRequest(
                List.of(Map.of("role", "user", "content", "Q")),
                "k", null, null, null, null));

        long start = System.currentTimeMillis();
        for (int i = 0; i < threads; i++) {
            pool.submit(() -> {
                try {
                    mockMvc.perform(post("/api/chat")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content(body))
                            .andExpect(status().isOk());
                } catch (Exception e) {
                    throw new RuntimeException(e);
                } finally {
                    latch.countDown();
                }
            });
        }

        assertTrue(latch.await(10, TimeUnit.SECONDS),
                "Параллельные chat-запросы не завершились за 10 секунд");
        pool.shutdown();
    }
}
