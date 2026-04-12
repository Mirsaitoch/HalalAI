package com.halalai.backend.service;

import com.halalai.backend.dto.ChatResponse;
import java.util.List;
import java.util.Map;

public interface ILLMService {
    ChatResponse generateCompletion(List<Map<String, String>> messages, String apiKey, String remoteModel, Integer maxTokens);
}
