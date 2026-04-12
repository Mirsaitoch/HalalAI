package com.halalai.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ConfigService implements IConfigService {

    private final String defaultModel;
    private final List<String> allowedModels;

    public ConfigService(
            @Value("${llm.models.default}") String defaultModel,
            @Value("${llm.models.allowed}") String allowedModelsStr) {
        this.defaultModel = defaultModel;
        this.allowedModels = List.of(allowedModelsStr.split(","));
    }

    public Map<String, Object> getAvailableModels() {
        Map<String, Object> result = new HashMap<>();
        result.put("default_model", defaultModel);
        result.put("allowed_models", allowedModels);
        return result;
    }
}
