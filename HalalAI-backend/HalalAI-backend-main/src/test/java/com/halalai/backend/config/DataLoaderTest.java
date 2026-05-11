package com.halalai.backend.config;

import com.halalai.backend.model.Verse;
import com.halalai.backend.repository.VerseRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DataLoaderTest {

    @Mock
    private VerseRepository verseRepository;

    @Test
    void run_skipsWhenDatabaseNotEmpty() throws Exception {
        when(verseRepository.count()).thenReturn(5L);

        var sut = new DataLoader(verseRepository);
        sut.run();

        verify(verseRepository, never()).save(any(Verse.class));
    }

    @Test
    void run_loadsFromTestCsv_andSkipsBadLines() throws Exception {
        when(verseRepository.count()).thenReturn(0L);

        var sut = new DataLoader(verseRepository);
        sut.run();

        // In src/test/resources/sury.csv два валидных aята (один с verse_number=null тоже допустим)
        verify(verseRepository, times(2)).save(any(Verse.class));
    }
}

