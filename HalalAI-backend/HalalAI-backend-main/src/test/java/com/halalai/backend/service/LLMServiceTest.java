package com.halalai.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.halalai.backend.dto.ChatResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

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
    private static final String SYSTEM_PROMPT = "Test system prompt";

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        llmService = new LLMService(restTemplate, LLM_SERVICE_URL, DEFAULT_MAX_TOKENS, SYSTEM_PROMPT);
    }

    @Test
    void testGenerateCompletionSuccess() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Привет")
        );

        String responseJson = """
                {
                    "reply": "Ответ от AI",
                    "model": "test-model",
                    "used_remote": false,
                    "remote_error": null
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(
                eq(LLM_SERVICE_URL + "/chat"),
                any(),
                any(),
                eq(JsonNode.class)
        )).thenReturn(responseEntity);

        ChatResponse response = llmService.generateCompletion(
                messages,
                null,
                null,
                null
        );

        assertNotNull(response);
        assertEquals("Ответ от AI", response.reply());
        assertEquals("test-model", response.model());
        assertFalse(response.usedRemote());
        // remoteError может быть null или пустой строкой, если в JSON было null
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
                    "model": "model",
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
                    "model": "model",
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
                512
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
                    "model": "remote-model",
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
                null
        );

        assertNotNull(response);
        assertEquals("remote-model", response.model());
        assertTrue(response.usedRemote());
    }

    @Test
    void testGenerateCompletionEmptyResponse() throws Exception {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "user", "content", "Вопрос")
        );

        String responseJson = """
                {
                    "reply": "",
                    "model": "model"
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(responseEntity);

        assertThrows(RuntimeException.class, () -> {
            llmService.generateCompletion(messages, null, null, null);
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
            llmService.generateCompletion(messages, null, null, null);
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
            llmService.generateCompletion(messages, null, null, null);
        });

        assertTrue(thrown.getMessage().contains("Не удалось подключиться к LLM сервису"));
    }

    @Test
    void testGenerateCompletionNullMessages() {
        assertThrows(IllegalArgumentException.class, () -> {
            llmService.generateCompletion(null, null, null, null);
        });
    }

    @Test
    void testFetchModelsSuccess() throws Exception {
        String responseJson = """
                {
                    "default_model": "test-model",
                    "allowed_models": ["model1", "model2", "model3"]
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(
                eq(LLM_SERVICE_URL + "/models"),
                any(),
                any(),
                eq(JsonNode.class)
        )).thenReturn(responseEntity);

        Map<String, Object> result = llmService.fetchModels();

        assertNotNull(result);
        assertEquals("test-model", result.get("default_model"));
        assertNotNull(result.get("allowed_models"));
    }

    @Test
    void testFetchModelsEmptyAllowed() throws Exception {
        String responseJson = """
                {
                    "default_model": "test-model"
                }
                """;

        JsonNode responseNode = objectMapper.readTree(responseJson);
        ResponseEntity<JsonNode> responseEntity = new ResponseEntity<>(responseNode, HttpStatus.OK);

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenReturn(responseEntity);

        Map<String, Object> result = llmService.fetchModels();

        assertNotNull(result);
        assertEquals("test-model", result.get("default_model"));
        assertTrue(result.containsKey("allowed_models"));
    }

    @Test
    void testFetchModelsError() {
        RestClientException exception = new RestClientException("Connection error");

        when(restTemplate.exchange(anyString(), any(), any(), eq(JsonNode.class)))
                .thenThrow(exception);

        assertThrows(RuntimeException.class, () -> {
            llmService.fetchModels();
        });
    }
}

