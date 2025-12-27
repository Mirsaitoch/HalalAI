package com.halalai.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record ChatResponse(
        String reply,
        String model,
        @JsonProperty("used_remote") Boolean usedRemote,
        @JsonProperty("remote_error") String remoteError
) {
}

