package com.halalai.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.halalai.backend.config.SecurityConfig;
import com.halalai.backend.controller.ChatController;
import com.halalai.backend.exception.GlobalExceptionHandler;
import com.halalai.backend.security.JwtAuthenticationFilter;
import com.halalai.backend.security.JwtTokenProvider;
import com.halalai.backend.service.IConfigService;
import com.halalai.backend.service.ILLMService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * 4.4.5 Проверка безопасности системы.
 *
 * Тесты выполняются с <b>реальной цепочкой Spring Security</b> (без addFilters=false).
 * Проверяются: контроль доступа, валидность JWT, CORS-заголовки, обработка
 * некорректных входных данных.
 */
@WebMvcTest(controllers = ChatController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JwtTokenProvider.class,
        GlobalExceptionHandler.class})
@TestPropertySource(properties = {
        "jwt.secret=0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF",
        "jwt.expiration=3600000",
        "llm.service.url=http://localhost:8000",
        "llm.service.max-tokens=256",
        "llm.models.default=test-model",
        "llm.models.allowed=test-model"
})
class SecurityMvcTest {

    private static final String TEST_SECRET =
            "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF";

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired JwtTokenProvider jwtTokenProvider;

    @MockBean UserDetailsService userDetailsService;
    @MockBean ILLMService llmService;
    @MockBean IConfigService configService;

    // ── Защищённые эндпоинты требуют аутентификации ───────────────────────────

    @Test
    void chat_withoutToken_isRejected() throws Exception {
        var result = mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                Map.of("messages",
                                        List.of(Map.of("role", "user", "content", "Q"))))))
                .andReturn();

        int status = result.getResponse().getStatus();
        assertTrue(status == 401 || status == 403,
                "Ожидался 401 или 403 без токена, получен: " + status);
    }

    @Test
    void chat_withInvalidJwt_isRejected() throws Exception {
        var result = mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer invalid.jwt.token")
                        .content(objectMapper.writeValueAsString(
                                Map.of("messages",
                                        List.of(Map.of("role", "user", "content", "Q"))))))
                .andReturn();

        int status = result.getResponse().getStatus();
        assertTrue(status == 401 || status == 403,
                "Ожидался 401 или 403 для невалидного JWT, получен: " + status);
    }

    @Test
    void chat_withExpiredToken_isRejected() throws Exception {
        var expiredProvider = new JwtTokenProvider();
        setField(expiredProvider, "secret", TEST_SECRET);
        setField(expiredProvider, "expiration", 1L);
        String expiredToken = expiredProvider.generateToken("a@b.com", 1L);
        Thread.sleep(10);

        var result = mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + expiredToken)
                        .content(objectMapper.writeValueAsString(
                                Map.of("messages",
                                        List.of(Map.of("role", "user", "content", "Q"))))))
                .andReturn();

        int status = result.getResponse().getStatus();
        assertTrue(status == 401 || status == 403,
                "Ожидался 401 или 403 для истекшего токена, получен: " + status);
    }

    @Test
    void chat_withTokenSignedByWrongKey_isRejected() throws Exception {
        var wrongKeyProvider = new JwtTokenProvider();
        setField(wrongKeyProvider, "secret", "WRONG_KEY_00000000000000000000000000000000");
        setField(wrongKeyProvider, "expiration", 3_600_000L);
        String forgedToken = wrongKeyProvider.generateToken("hacker@evil.com", 999L);

        var result = mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + forgedToken)
                        .content(objectMapper.writeValueAsString(
                                Map.of("messages",
                                        List.of(Map.of("role", "user", "content", "Q"))))))
                .andReturn();

        int status = result.getResponse().getStatus();
        assertTrue(status == 401 || status == 403,
                "Токен с чужим ключом должен быть отвергнут, получен: " + status);
    }

    @Test
    void chat_withGarbledAuthorizationHeader_isRejected() throws Exception {
        var result = mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "' OR '1'='1")
                        .content(objectMapper.writeValueAsString(
                                Map.of("messages",
                                        List.of(Map.of("role", "user", "content", "Q"))))))
                .andReturn();

        int status = result.getResponse().getStatus();
        assertTrue(status == 401 || status == 403,
                "Мусорный заголовок Authorization должен быть отвергнут, получен: " + status);
    }

    // ── Аутентифицированный запрос проходит ──────────────────────────────────

    @Test
    void chat_withValidToken_isAccepted() throws Exception {
        String token = jwtTokenProvider.generateToken("user@b.com", 1L);

        var userDetails = User.withUsername("user@b.com")
                .password("x")
                .authorities("ROLE_USER")
                .build();
        when(userDetailsService.loadUserByUsername("user@b.com")).thenReturn(userDetails);
        when(llmService.generateCompletion(anyList(), any(), any(), any(), any(), any()))
                .thenReturn(new com.halalai.backend.dto.ChatResponse("Ответ", true, null));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + token)
                        .content(objectMapper.writeValueAsString(
                                Map.of("messages",
                                        List.of(Map.of("role", "user", "content", "Q"))))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("Ответ"));
    }

    // ── Публичные эндпоинты доступны без токена ───────────────────────────────

    @Test
    void models_publicEndpoint_accessibleWithoutToken() throws Exception {
        when(configService.getAvailableModels()).thenReturn(Map.of("default", "m1"));

        mockMvc.perform(get("/api/models"))
                .andExpect(status().isOk());
    }

    // ── CORS ──────────────────────────────────────────────────────────────────

    @Test
    void corsPreflightRequest_containsAllowOriginHeader() throws Exception {
        mockMvc.perform(options("/api/chat")
                        .header("Origin", "http://example.com")
                        .header("Access-Control-Request-Method", "POST"))
                .andExpect(header().exists("Access-Control-Allow-Origin"));
    }

    @Test
    void corsPostRequest_containsAllowOriginHeader() throws Exception {
        when(configService.getAvailableModels()).thenReturn(Map.of("default", "m1"));

        mockMvc.perform(get("/api/models")
                        .header("Origin", "http://mobile-app.example"))
                .andExpect(header().exists("Access-Control-Allow-Origin"));
    }

    // ── Вспомогательный метод ─────────────────────────────────────────────────

    private static void setField(Object target, String field, Object value) throws Exception {
        var f = target.getClass().getDeclaredField(field);
        f.setAccessible(true);
        f.set(target, value);
    }
}
