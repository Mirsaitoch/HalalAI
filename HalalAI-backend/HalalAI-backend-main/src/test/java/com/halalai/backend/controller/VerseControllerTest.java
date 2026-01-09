package com.halalai.backend.controller;

import com.halalai.backend.dto.VerseResponse;
import com.halalai.backend.service.VerseService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VerseControllerTest {

    @Mock
    private VerseService verseService;

    @InjectMocks
    private VerseController verseController;

    private VerseResponse testVerseResponse;

    @BeforeEach
    void setUp() {
        testVerseResponse = new VerseResponse(
                1L,
                1,
                "АЛЬ-фАТИХА",
                "«ОТКРЫВАЮЩАЯ КОРАН»",
                1,
                "Во имя Аллаха, Милостивого, Милосердного!"
        );
    }

    @Test
    void testGetVerseOfTheDay_Success() {
        // Arrange
        when(verseService.getVerseOfTheDay()).thenReturn(testVerseResponse);

        // Act
        ResponseEntity<VerseResponse> response = verseController.getVerseOfTheDay();

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        
        VerseResponse body = response.getBody();
        assertEquals(testVerseResponse.id(), body.id());
        assertEquals(testVerseResponse.suraIndex(), body.suraIndex());
        assertEquals(testVerseResponse.suraTitle(), body.suraTitle());
        assertEquals(testVerseResponse.suraSubtitle(), body.suraSubtitle());
        assertEquals(testVerseResponse.verseNumber(), body.verseNumber());
        assertEquals(testVerseResponse.text(), body.text());

        verify(verseService).getVerseOfTheDay();
    }

    @Test
    void testGetVerseOfTheDay_ServiceThrowsException() {
        // Arrange
        RuntimeException exception = new RuntimeException("База данных аятов пуста. Пожалуйста, загрузите данные.");
        when(verseService.getVerseOfTheDay()).thenThrow(exception);

        // Act & Assert
        assertThrows(RuntimeException.class, () -> verseController.getVerseOfTheDay());
        
        verify(verseService).getVerseOfTheDay();
    }

    @Test
    void testGetVerseOfTheDay_WithDifferentVerse() {
        // Arrange
        VerseResponse differentVerse = new VerseResponse(
                2L,
                1,
                "АЛЬ-фАТИХА",
                "«ОТКРЫВАЮЩАЯ КОРАН»",
                2,
                "Хвала Аллаху, Господу миров,"
        );
        when(verseService.getVerseOfTheDay()).thenReturn(differentVerse);

        // Act
        ResponseEntity<VerseResponse> response = verseController.getVerseOfTheDay();

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(differentVerse.id(), response.getBody().id());
        assertEquals(differentVerse.text(), response.getBody().text());

        verify(verseService).getVerseOfTheDay();
    }
}

