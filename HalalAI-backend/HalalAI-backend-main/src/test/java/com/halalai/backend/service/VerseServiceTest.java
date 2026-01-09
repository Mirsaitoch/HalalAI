package com.halalai.backend.service;

import com.halalai.backend.dto.VerseResponse;
import com.halalai.backend.model.Verse;
import com.halalai.backend.repository.VerseRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VerseServiceTest {

    @Mock
    private VerseRepository verseRepository;

    @InjectMocks
    private VerseService verseService;

    private Verse testVerse1;
    private Verse testVerse2;
    private Verse testVerse3;

    @BeforeEach
    void setUp() {
        testVerse1 = new Verse();
        testVerse1.setId(1L);
        testVerse1.setSuraIndex(1);
        testVerse1.setSuraTitle("АЛЬ-фАТИХА");
        testVerse1.setSuraSubtitle("«ОТКРЫВАЮЩАЯ КОРАН»");
        testVerse1.setVerseNumber(1);
        testVerse1.setText("Во имя Аллаха, Милостивого, Милосердного!");

        testVerse2 = new Verse();
        testVerse2.setId(2L);
        testVerse2.setSuraIndex(1);
        testVerse2.setSuraTitle("АЛЬ-фАТИХА");
        testVerse2.setSuraSubtitle("«ОТКРЫВАЮЩАЯ КОРАН»");
        testVerse2.setVerseNumber(2);
        testVerse2.setText("Хвала Аллаху, Господу миров,");

        testVerse3 = new Verse();
        testVerse3.setId(3L);
        testVerse3.setSuraIndex(2);
        testVerse3.setSuraTitle("АЛЬ-БАКАРА");
        testVerse3.setSuraSubtitle("«КОРОВА»");
        testVerse3.setVerseNumber(1);
        testVerse3.setText("Алиф. Лам. Мим.");
    }

    @Test
    void testGetVerseOfTheDay_Success() {
        // Arrange
        long totalVerses = 3L;
        LocalDate today = LocalDate.now();
        long dayOfYear = today.getDayOfYear();
        int expectedIndex = (int) ((dayOfYear - 1) % totalVerses);
        
        List<Verse> verseList = Arrays.asList(testVerse1, testVerse2, testVerse3);
        Page<Verse> versePage = new PageImpl<>(List.of(verseList.get(expectedIndex)));

        when(verseRepository.count()).thenReturn(totalVerses);
        when(verseRepository.findAllByOrderByIdAsc(any(PageRequest.class)))
                .thenReturn(versePage);

        // Act
        VerseResponse response = verseService.getVerseOfTheDay();

        // Assert
        assertNotNull(response);
        assertEquals(verseList.get(expectedIndex).getId(), response.id());
        assertEquals(verseList.get(expectedIndex).getSuraIndex(), response.suraIndex());
        assertEquals(verseList.get(expectedIndex).getSuraTitle(), response.suraTitle());
        assertEquals(verseList.get(expectedIndex).getSuraSubtitle(), response.suraSubtitle());
        assertEquals(verseList.get(expectedIndex).getVerseNumber(), response.verseNumber());
        assertEquals(verseList.get(expectedIndex).getText(), response.text());

        verify(verseRepository).count();
        verify(verseRepository).findAllByOrderByIdAsc(any(PageRequest.class));
    }

    @Test
    void testGetVerseOfTheDay_EmptyDatabase() {
        // Arrange
        when(verseRepository.count()).thenReturn(0L);

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, 
                () -> verseService.getVerseOfTheDay());
        
        assertEquals("База данных аятов пуста. Пожалуйста, загрузите данные.", exception.getMessage());
        
        verify(verseRepository).count();
        verify(verseRepository, never()).findAllByOrderByIdAsc(any(PageRequest.class));
    }

    @Test
    void testGetVerseOfTheDay_WithWrappingIndex() {
        // Arrange - симулируем случай, когда день года больше количества аятов
        long totalVerses = 2L;
        // Предположим, что день года = 365, тогда индекс будет (365 - 1) % 2 = 0
        LocalDate today = LocalDate.of(2024, 12, 31); // 366-й день високосного года
        long dayOfYear = today.getDayOfYear();
        int expectedIndex = (int) ((dayOfYear - 1) % totalVerses);
        
        Page<Verse> versePage = new PageImpl<>(List.of(testVerse1));

        when(verseRepository.count()).thenReturn(totalVerses);
        when(verseRepository.findAllByOrderByIdAsc(any(PageRequest.class)))
                .thenReturn(versePage);

        // Act
        VerseResponse response = verseService.getVerseOfTheDay();

        // Assert
        assertNotNull(response);
        assertEquals(testVerse1.getId(), response.id());
        verify(verseRepository).count();
        verify(verseRepository).findAllByOrderByIdAsc(any(PageRequest.class));
    }

    @Test
    void testGetVerseOfTheDay_Consistency() {
        // Arrange - проверяем, что в один день возвращается один и тот же аят
        long totalVerses = 3L;
        LocalDate fixedDate = LocalDate.of(2024, 6, 15);
        long dayOfYear = fixedDate.getDayOfYear();
        int expectedIndex = (int) ((dayOfYear - 1) % totalVerses);
        
        List<Verse> verseList = Arrays.asList(testVerse1, testVerse2, testVerse3);
        Page<Verse> versePage = new PageImpl<>(List.of(verseList.get(expectedIndex)));

        when(verseRepository.count()).thenReturn(totalVerses);
        when(verseRepository.findAllByOrderByIdAsc(any(PageRequest.class)))
                .thenReturn(versePage);

        // Act - вызываем дважды
        VerseResponse response1 = verseService.getVerseOfTheDay();
        VerseResponse response2 = verseService.getVerseOfTheDay();

        // Assert - должны получить одинаковый результат
        assertEquals(response1.id(), response2.id());
        assertEquals(response1.text(), response2.text());
    }
}

