package com.halalai.backend.controller;

import com.halalai.backend.dto.VerseResponse;
import com.halalai.backend.service.VerseService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class VerseController {

    private static final Logger logger = LoggerFactory.getLogger(VerseController.class);
    private final VerseService verseService;

    public VerseController(VerseService verseService) {
        this.verseService = verseService;
    }

    @GetMapping("/verse-of-the-day")
    public ResponseEntity<VerseResponse> getVerseOfTheDay() {
        logger.info("GET /api/verse-of-the-day");
        VerseResponse response = verseService.getVerseOfTheDay();
        return ResponseEntity.ok(response);
    }
}

