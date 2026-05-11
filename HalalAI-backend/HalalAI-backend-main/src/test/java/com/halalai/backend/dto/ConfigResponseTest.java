package com.halalai.backend.dto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ConfigResponseTest {

    @Test
    void record_instantiatesAndReturnsValue() {
        var r = new ConfigResponse("prompt");
        assertEquals("prompt", r.systemPrompt());
    }
}

