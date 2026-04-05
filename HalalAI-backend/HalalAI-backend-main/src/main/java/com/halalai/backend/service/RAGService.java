package com.halalai.backend.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.JsonNode;
import com.halalai.backend.dto.RAGRequest;
import com.halalai.backend.dto.RAGResponse;

@Service
public class RAGService {

    private static final Logger logger = LoggerFactory.getLogger(RAGService.class);

    private final RestTemplate restTemplate;
    private final String ragServiceUrl;

    public RAGService(
            RestTemplate restTemplate,
            @Value("${rag.service.url:http://localhost:8001}") String ragServiceUrl) {
        this.restTemplate = restTemplate;
        this.ragServiceUrl = ragServiceUrl;

        logger.info("Инициализация RAG Service... URL: {}", ragServiceUrl);
    }

    public RAGResponse search(String query, Integer topK) {
        logger.debug("Поиск по запросу: {}", query);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("query", query);
        requestBody.put("top_k", topK != null ? topK : 5);

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
        String searchUrl = ragServiceUrl + "/search";

        try {
            logger.debug("Отправка поиска к RAG сервису: {}", searchUrl);

            ResponseEntity<JsonNode> responseEntity = restTemplate.exchange(
                    searchUrl,
                    HttpMethod.POST,
                    requestEntity,
                    JsonNode.class
            );

            logger.debug("Получен ответ от RAG сервиса. Статус: {}", responseEntity.getStatusCode());

            JsonNode responseBody = responseEntity.getBody();
            if (responseBody == null) {
                throw new RuntimeException("RAG сервис вернул пустой ответ");
            }

            return buildRAGResponse(query, responseBody);

        } catch (org.springframework.web.client.HttpClientErrorException e) {
            logger.error("Ошибка HTTP при обращении к RAG сервису: статус={}, URL={}, тело={}",
                    e.getStatusCode(), searchUrl, e.getResponseBodyAsString());
            throw new ResponseStatusException(e.getStatusCode(), "Ошибка RAG сервиса: " + e.getResponseBodyAsString(), e);

        } catch (org.springframework.web.client.ResourceAccessException e) {
            logger.error("Ошибка подключения к RAG сервису: URL={}, сообщение={}", searchUrl, e.getMessage());
            throw new RuntimeException("Не удалось подключиться к RAG сервису по адресу " + searchUrl, e);

        } catch (RestClientException e) {
            logger.error("Ошибка REST клиента при обращении к RAG сервису: URL={}, сообщение={}", searchUrl, e.getMessage());
            throw new RuntimeException("Не удалось подключиться к RAG сервису по адресу " + searchUrl, e);
        } catch (Exception e) {
            logger.error("Неизвестная ошибка при поиске: {}", e.getMessage(), e);
            throw new RuntimeException("Ошибка при поиске: " + e.getMessage(), e);
        }
    }

    public RAGResponse qa(RAGRequest request) {
        logger.debug("QA запрос: query={}, use_llm={}, model={}",
                request.query(), request.useLlm(), request.model());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("query", request.query());
        requestBody.put("top_k", request.topK());
        requestBody.put("use_llm", request.useLlm());
        requestBody.put("model", request.model());

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
        String qaUrl = ragServiceUrl + "/qa";

        try {
            logger.debug("Отправка QA запроса к RAG сервису: {}", qaUrl);

            ResponseEntity<JsonNode> responseEntity = restTemplate.exchange(
                    qaUrl,
                    HttpMethod.POST,
                    requestEntity,
                    JsonNode.class
            );

            logger.debug("Получен ответ от RAG сервиса. Статус: {}", responseEntity.getStatusCode());

            JsonNode responseBody = responseEntity.getBody();
            if (responseBody == null) {
                throw new RuntimeException("RAG сервис вернул пустой ответ");
            }

            logger.info("QA ответ получен: sources={}, answer_length={}",
                    responseBody.path("sources").size(),
                    responseBody.path("answer").isNull() ? 0 : responseBody.path("answer").asText("").length());

            return buildRAGResponse(request.query(), responseBody);

        } catch (org.springframework.web.client.HttpClientErrorException e) {
            logger.error("Ошибка HTTP при обращении к RAG сервису: статус={}, URL={}, тело={}",
                    e.getStatusCode(), qaUrl, e.getResponseBodyAsString());
            throw new ResponseStatusException(e.getStatusCode(), "Ошибка RAG сервиса: " + e.getResponseBodyAsString(), e);

        } catch (org.springframework.web.client.ResourceAccessException e) {
            logger.error("Ошибка подключения к RAG сервису: URL={}, сообщение={}", qaUrl, e.getMessage());
            throw new RuntimeException("Не удалось подключиться к RAG сервису по адресу " + qaUrl, e);

        } catch (RestClientException e) {
            logger.error("Ошибка REST клиента при обращении к RAG сервису: URL={}, сообщение={}", qaUrl, e.getMessage());
            throw new RuntimeException("Не удалось подключиться к RAG сервису по адресу " + qaUrl, e);
        } catch (Exception e) {
            logger.error("Неизвестная ошибка при QA: {}", e.getMessage(), e);
            throw new RuntimeException("Ошибка при QA: " + e.getMessage(), e);
        }
    }

    private RAGResponse buildRAGResponse(String query, JsonNode responseBody) {
        logger.info("Building RAG Response...");
        try {
            List<Map<String, Object>> sources = new ArrayList<>();

            // Handle both "results" (from /search) and "sources" (from /qa)
            JsonNode sourcesNode = responseBody.has("sources") ? responseBody.path("sources") : responseBody.path("results");

            logger.info("Sources node present: {}, is array: {}", sourcesNode != null, sourcesNode != null && sourcesNode.isArray());

            if (sourcesNode != null && sourcesNode.isArray()) {
                for (JsonNode sourceNode : sourcesNode) {
                    // Convert JsonNode to Map manually
                    Map<String, Object> source = new java.util.HashMap<>();
                    sourceNode.fields().forEachRemaining(entry -> {
                        JsonNode value = entry.getValue();
                        source.put(entry.getKey(), value.isValueNode() ? value.asText() : value);
                    });
                    sources.add(source);
                }
            }

            logger.info("Parsed {} sources", sources.size());

            String answer = null;
            if (responseBody.has("answer") && !responseBody.path("answer").isNull()) {
                answer = responseBody.path("answer").asText();
            }

            logger.info("RAG Response parsed: {} sources, answer length={}", sources.size(), answer != null ? answer.length() : 0);

            return new RAGResponse(query, sources, answer, null);
        } catch (Exception e) {
            logger.error("Ошибка при парсинге ответа RAG: {}", e.getMessage(), e);
            throw new RuntimeException("Ошибка при парсинге ответа RAG: " + e.getMessage(), e);
        }
    }
}
