package com.halalai.backend.dto;

import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;

public record RAGResponse(
    String query,
    List<Map<String, Object>> sources,
    String answer,
    @JsonProperty("quality_assessment") Map<String, Object> qualityAssessment
) {
}
