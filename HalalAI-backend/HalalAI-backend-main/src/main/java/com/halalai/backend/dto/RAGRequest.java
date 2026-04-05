package com.halalai.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record RAGRequest(
    String query,
    @JsonProperty("top_k") Integer topK,
    @JsonProperty("use_llm") Boolean useLlm,
    String model
) {
    public RAGRequest {
        topK = topK != null ? topK : 3;
        useLlm = useLlm != null ? useLlm : true;
        model = model != null ? model : "qwen/qwen3.6-plus:free";
    }
}
