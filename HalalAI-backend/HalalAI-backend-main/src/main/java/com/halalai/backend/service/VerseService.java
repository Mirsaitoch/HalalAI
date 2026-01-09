package com.halalai.backend.service;

import com.halalai.backend.dto.VerseResponse;
import com.halalai.backend.model.Verse;
import com.halalai.backend.repository.VerseRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@Service
public class VerseService {

    private static final Logger logger = LoggerFactory.getLogger(VerseService.class);
    private final VerseRepository verseRepository;

    public VerseService(VerseRepository verseRepository) {
        this.verseRepository = verseRepository;
    }

    public VerseResponse getVerseOfTheDay() {
        long totalVerses = verseRepository.count();
        
        if (totalVerses == 0) {
            logger.warn("База данных аятов пуста");
            throw new RuntimeException("База данных аятов пуста. Пожалуйста, загрузите данные.");
        }

        // Используем день года (1-365/366) для выбора аята
        // Это гарантирует, что один и тот же аят будет возвращаться в течение дня
        LocalDate today = LocalDate.now();
        LocalDate startOfYear = LocalDate.of(today.getYear(), 1, 1);
        long dayOfYear = ChronoUnit.DAYS.between(startOfYear, today) + 1;
        
        // Используем день года как индекс для выбора аята
        int verseIndex = (int) ((dayOfYear - 1) % totalVerses);
        
        // Используем пагинацию для эффективного получения одного аята
        Verse verse = verseRepository.findAllByOrderByIdAsc(
                PageRequest.of(verseIndex, 1)
        ).getContent().get(0);
        
        logger.info("Возвращен аят дня: сура {}, аят {}", verse.getSuraIndex(), verse.getVerseNumber());
        
        return new VerseResponse(
                verse.getId(),
                verse.getSuraIndex(),
                verse.getSuraTitle(),
                verse.getSuraSubtitle(),
                verse.getVerseNumber(),
                verse.getText()
        );
    }
}

