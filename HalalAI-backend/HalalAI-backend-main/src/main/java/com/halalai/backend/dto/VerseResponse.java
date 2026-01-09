package com.halalai.backend.dto;

public record VerseResponse(
        Long id,
        Integer suraIndex,
        String suraTitle,
        String suraSubtitle,
        Integer verseNumber,
        String text
) {
}

