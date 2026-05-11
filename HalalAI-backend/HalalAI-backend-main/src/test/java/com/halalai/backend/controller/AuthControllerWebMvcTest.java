package com.halalai.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.halalai.backend.dto.AuthResponse;
import com.halalai.backend.dto.LoginRequest;
import com.halalai.backend.dto.RefreshTokenRequest;
import com.halalai.backend.dto.RegisterRequest;
import com.halalai.backend.service.IAuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithAnonymousUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.boot.test.mock.mockito.MockBean;
import com.halalai.backend.security.JwtAuthenticationFilter;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = AuthController.class)
@Import(com.halalai.backend.exception.GlobalExceptionHandler.class)
@AutoConfigureMockMvc(addFilters = false)
class AuthControllerWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private IAuthService authService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    @WithAnonymousUser
    void register_returns201AndBody() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn(new AuthResponse("tok", "Bearer", 1L, "a@b.com"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RegisterRequest("a@b.com", "password123"))))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.token").value("tok"))
                .andExpect(jsonPath("$.type").value("Bearer"))
                .andExpect(jsonPath("$.userId").value(1))
                .andExpect(jsonPath("$.email").value("a@b.com"));
    }

    @Test
    @WithAnonymousUser
    void login_returns200AndBody() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("tok", "Bearer", 2L, "u@b.com"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new LoginRequest("u@b.com", "pass"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("tok"))
                .andExpect(jsonPath("$.userId").value(2))
                .andExpect(jsonPath("$.email").value("u@b.com"));
    }

    @Test
    @WithAnonymousUser
    void refresh_returns200AndBody() throws Exception {
        when(authService.refreshToken("old"))
                .thenReturn(new AuthResponse("new", "Bearer", 3L, "x@y.com"));

        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RefreshTokenRequest("old"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("new"))
                .andExpect(jsonPath("$.userId").value(3))
                .andExpect(jsonPath("$.email").value("x@y.com"));
    }

    @Test
    @WithAnonymousUser
    void register_invalidEmail_returns400ValidationMap() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RegisterRequest("not-an-email", "password123"))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Ошибка валидации"))
                .andExpect(jsonPath("$.errors.email", containsString("валидным")))
                .andExpect(jsonPath("$.path").value("/api/auth/register"));
    }

    @Test
    @WithAnonymousUser
    void register_shortPassword_returns400ValidationMap() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RegisterRequest("a@b.com", "short"))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.password", containsString("минимум 8")));
    }

    @Test
    @WithAnonymousUser
    void login_blankPassword_returns400ValidationMap() throws Exception {
        // record allows nulls but @NotBlank triggers on empty string; pass empty to hit MethodArgumentNotValidException
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"a@b.com\",\"password\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.password", containsString("не может быть пустым")));
    }

    @Test
    @WithAnonymousUser
    void refresh_blankToken_returns400ValidationMap() throws Exception {
        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.token", containsString("не может быть пустым")));
    }
}

