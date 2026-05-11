package com.halalai.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.halalai.backend.dto.ChatResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LLMServiceTest {

    @Mock
    private RestTemplate restTemplate;

    private LLMService llmService;

    private static final String LLM_SERVICE_URL = "http://localhost:8000";
    private static final int DEFAULT_MAX_TOKENS = 256;
    private static final String DEFAULT_MODEL = "test-default";
    private static final String ALLOWED_MODELS = "model1,model2,test-model";

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        llmService = new LLMService(
                restTemplate,
                LLM_SERVICE_URL,
                DEFAULT_MAX_TOKENS,
                DEFAULT_MODEL,
                ALLOWED_MODELS
        );
    }

    @Test
    void testGenerateCompletionSuccess() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Привет")
        );

        String responseJson = """
                {
                    "reply": "Ответ от AI",
                    "used_remote": false,
                    "remote_error": null
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(
                eq(LLM_SERVICE_URL + "/llm/chat"),
                any(),
                any(),
                eq(JsonNode.class)
        )).thenReturn(responseEntity);

        ChatResponse response = llmService.generateCompletion(
                messages,
                null,
                null,
                null,
                null,
                null
        );

        assertNotNull(response);
        assertEquals("Ответ от AI", response.reply());
        assertFalse(response.usedRemote());
        assertTrue(response.remoteError() == null || response.remoteError().isEmpty());
    }

    @Test
    void testGenerateCompletionWithSystemPrompt() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        String responseJson = """
                {
                    "reply": "Ответ",
                    "used_remote": true,
                    "remote_error": null
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(responseEntity);

        ChatResponse response = llmService.generateCompletion(
                messages,
                null,
                null,
                null,
                null,
                null
        );

        assertNotNull(response);
        assertEquals("Ответ", response.reply());
        assertTrue(response.usedRemote());
    }

    @Test
    void testGenerateCompletionWithCustomMaxTokens() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        String responseJson = """
                {
                    "reply": "Ответ",
                    "used_remote": false
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(responseEntity);

        ChatResponse response = llmService.generateCompletion(
                messages,
                null,
                null,
                512,
                null,
                null
        );

        assertNotNull(response);
        assertEquals("Ответ", response.reply());
    }

    @Test
    void testGenerateCompletionWithApiKeyAndRemoteModel() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        String responseJson = """
                {
                    "reply": "Ответ",
                    "used_remote": true
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(responseEntity);

        ChatResponse response = llmService.generateCompletion(
                messages,
                "api-key-123",
                "remote-model",
                null,
                null,
                null
        );

        assertNotNull(response);
        assertEquals("Ответ", response.reply());
        assertTrue(response.usedRemote());
    }

    @Test
    void testGenerateCompletionEmptyResponse() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        String responseJson = """
                {
                    "reply": ""
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(responseEntity);

        assertThrows(RuntimeException.class, () -> {
            llmService.generateCompletion(messages, null, null, null, null, null);
        });
    }

    @Test
    void testGenerateCompletionServiceUnavailable() {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        HttpClientErrorException exception = new HttpClientErrorException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "Service unavailable"
        );

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenThrow(exception);

        RuntimeException thrown = assertThrows(RuntimeException.class, () -> {
            llmService.generateCompletion(messages, null, null, null, null, null);
        });

        assertTrue(thrown.getMessage().contains("LLM сервис не готов"));
    }

    @Test
    void testGenerateCompletionConnectionError() {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        RestClientException exception = new RestClientException("Connection refused");

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenThrow(exception);

        RuntimeException thrown = assertThrows(RuntimeException.class, () -> {
            llmService.generateCompletion(messages, null, null, null, null, null);
        });

        assertTrue(thrown.getMessage().contains("Не удалось подключиться к LLM сервису"));
    }

    @Test
    void testGenerateCompletionNullMessages() {
        assertThrows(IllegalArgumentException.class, () -> {
            llmService.generateCompletion(null, null, null, null, null, null);
        });
    }

    @Test
    void testGenerateCompletionWithTemperatureAndRag() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        String responseJson = """
                {
                    "reply": "Ответ",
                    "used_remote": false,
                    "remote_error": ""
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(responseEntity);

        ChatResponse response = llmService.generateCompletion(
                messages,
                null,
                null,
                null,
                0.5,
                true
        );

        assertEquals("Ответ", response.reply());
        assertFalse(response.usedRemote());
        assertNull(response.remoteError());
    }

    @Test
    void testGenerateCompletionNullBody_throwsRuntime() {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(new ResponseEntity<>(null, HttpStatus.OK));

        assertThrows(RuntimeException.class, () -> llmService.generateCompletion(messages, null, null, null, null, null));
    }

    @Test
    void testGenerateCompletionRemoteErrorNonEmpty_propagates() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        String responseJson = """
                {
                    "reply": "Ответ",
                    "used_remote": true,
                    "remote_error": "upstream failed"
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(new ResponseEntity<>(responseNode, HttpStatus.OK));

        ChatResponse response = llmService.generateCompletion(messages, null, null, null, null, null);
        assertEquals("upstream failed", response.remoteError());
    }

    @Test
    void testGenerateCompletionHttpClientErrorNon503_throwsResponseStatusException() {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        HttpClientErrorException exception = new HttpClientErrorException(
                HttpStatus.BAD_REQUEST,
                "Bad Request",
                "body".getBytes(),
                java.nio.charset.StandardCharsets.UTF_8
        );

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenThrow(exception);

        assertThrows(ResponseStatusException.class, () -> llmService.generateCompletion(messages, null, null, null, null, null));
    }

    @Test
    void testGenerateCompletionResourceAccessException_branch() {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenThrow(new ResourceAccessException("timeout"));

        RuntimeException ex = assertThrows(RuntimeException.class, () -> llmService.generateCompletion(messages, null, null, null, null, null));
        assertTrue(ex.getMessage().contains("Не удалось подключиться"));
    }
}
