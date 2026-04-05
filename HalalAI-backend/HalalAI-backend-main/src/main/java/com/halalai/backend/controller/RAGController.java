package com.halalai.backend.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.halalai.backend.dto.RAGRequest;
import com.halalai.backend.dto.RAGResponse;
import com.halalai.backend.service.RAGService;

@RestController
@RequestMapping("/api/rag")
public class RAGController {

    private static final Logger logger = LoggerFactory.getLogger(RAGController.class);

    private final RAGService ragService;

    public RAGController(RAGService ragService) {
        this.ragService = ragService;
    }

    @PostMapping("/search")
    public RAGResponse search(@RequestBody RAGRequest request) {
        logger.info("Поиск: query={}, top_k={}", request.query(), request.topK());
        return ragService.search(request.query(), request.topK());
    }

    @PostMapping("/qa")
    public RAGResponse qa(@RequestBody RAGRequest request) {
        logger.info("QA запрос: query={}, use_llm={}, model={}",
                request.query(), request.useLlm(), request.model());
        return ragService.qa(request);
    }
}
