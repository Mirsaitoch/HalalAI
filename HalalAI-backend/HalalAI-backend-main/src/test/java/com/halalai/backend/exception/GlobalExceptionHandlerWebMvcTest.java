package com.halalai.backend.exception;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import org.springframework.boot.test.mock.mockito.MockBean;
import com.halalai.backend.security.JwtAuthenticationFilter;

@WebMvcTest(controllers = ThrowingControllerForExceptionHandlerTest.class)
@Import(GlobalExceptionHandler.class)
@AutoConfigureMockMvc(addFilters = false)
class GlobalExceptionHandlerWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    void methodArgumentNotValid_returns400WithFieldErrors() throws Exception {
        mockMvc.perform(post("/test/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Ошибка валидации"))
                .andExpect(jsonPath("$.errors", aMapWithSize(1)))
                .andExpect(jsonPath("$.errors.value", containsString("не может быть пустым")))
                .andExpect(jsonPath("$.path").value("/test/validate"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void constraintViolation_returns400WithErrorsMap() throws Exception {
        mockMvc.perform(get("/test/constraint"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Ошибка валидации"))
                .andExpect(jsonPath("$.errors", aMapWithSize(1)))
                .andExpect(jsonPath("$.errors.someField").value("must not be blank"))
                .andExpect(jsonPath("$.path").value("/test/constraint"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void illegalArgument_returns400ErrorResponse() throws Exception {
        mockMvc.perform(get("/test/illegal-arg"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("bad input"))
                .andExpect(jsonPath("$.path").value("/test/illegal-arg"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void badCredentials_returns401WithFixedMessage() throws Exception {
        mockMvc.perform(get("/test/bad-credentials"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Неверное имя пользователя или пароль"))
                .andExpect(jsonPath("$.path").value("/test/bad-credentials"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void usernameNotFound_returns401WithFixedMessage() throws Exception {
        mockMvc.perform(get("/test/username-not-found"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Пользователь не найден"))
                .andExpect(jsonPath("$.path").value("/test/username-not-found"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void runtimeException_returns500WithOriginalMessage() throws Exception {
        mockMvc.perform(get("/test/runtime"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("boom"))
                .andExpect(jsonPath("$.path").value("/test/runtime"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void unknownException_returns500WithGenericMessage() throws Exception {
        mockMvc.perform(get("/test/unknown"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Внутренняя ошибка сервера"))
                .andExpect(jsonPath("$.path").value("/test/unknown"))
                .andExpect(jsonPath("$.timestamp").exists());
    }
}

