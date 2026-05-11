package com.halalai.backend.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ConfigServiceTest {

    @Test
    void getAvailableModels_returnsDefaultAndAllowed() {
        var sut = new ConfigService("def", "m1,m2,def");

        var result = sut.getAvailableModels();

        assertEquals("def", result.get("default_model"));
        assertNotNull(result.get("allowed_models"));
        assertTrue(result.get("allowed_models").toString().contains("m1"));
    }
}

