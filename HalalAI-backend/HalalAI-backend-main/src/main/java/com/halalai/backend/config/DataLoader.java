package com.halalai.backend.config;

import com.halalai.backend.model.Verse;
import com.halalai.backend.repository.VerseRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

@Component
public class DataLoader implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DataLoader.class);
    private final VerseRepository verseRepository;

    public DataLoader(VerseRepository verseRepository) {
        this.verseRepository = verseRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        // Проверяем, есть ли уже данные в базе
        if (verseRepository.count() > 0) {
            logger.info("База данных аятов уже содержит {} записей. Пропускаем загрузку.", verseRepository.count());
            return;
        }

        logger.info("Начинаем загрузку аятов из CSV файла...");
        
        try {
            ClassPathResource resource = new ClassPathResource("sury.csv");
            int loadedCount = 0;
            int skippedCount = 0;

            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
                
                // Пропускаем заголовок
                String header = reader.readLine();
                if (header == null || !header.startsWith("sura_index")) {
                    logger.warn("Неверный формат CSV файла. Ожидается заголовок с 'sura_index'");
                    return;
                }

                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.trim().isEmpty()) {
                        continue;
                    }

                    try {
                        Verse verse = parseCsvLine(line);
                        if (verse != null) {
                            verseRepository.save(verse);
                            loadedCount++;
                            
                            if (loadedCount % 1000 == 0) {
                                logger.info("Загружено {} аятов...", loadedCount);
                            }
                        } else {
                            skippedCount++;
                        }
                    } catch (Exception e) {
                        logger.warn("Ошибка при парсинге строки: {}. Пропускаем. Ошибка: {}", line.substring(0, Math.min(50, line.length())), e.getMessage());
                        skippedCount++;
                    }
                }
            }

            logger.info("Загрузка завершена. Загружено: {}, Пропущено: {}, Всего в базе: {}", 
                    loadedCount, skippedCount, verseRepository.count());
        } catch (Exception e) {
            logger.error("Ошибка при загрузке данных из CSV: {}", e.getMessage(), e);
        }
    }

    private Verse parseCsvLine(String line) {
        // Простой парсинг CSV с учетом кавычек
        // Формат: sura_index,sura_title,sura_subtitle,verse_number,text
        try {
            String[] parts = parseCsvFields(line);
            
            if (parts.length < 5) {
                return null;
            }

            Integer suraIndex = parseInteger(parts[0]);
            String suraTitle = parts[1].trim();
            String suraSubtitle = parts[2].trim();
            Integer verseNumber = parseInteger(parts[3]);
            String text = parts[4].trim();

            if (suraIndex == null || suraTitle.isEmpty() || text.isEmpty()) {
                return null;
            }

            return new Verse(suraIndex, suraTitle, suraSubtitle, verseNumber, text);
        } catch (Exception e) {
            logger.debug("Ошибка парсинга строки: {}", e.getMessage());
            return null;
        }
    }

    private String[] parseCsvFields(String line) {
        // Простой парсер CSV, который учитывает кавычки
        java.util.List<String> fields = new java.util.ArrayList<>();
        StringBuilder currentField = new StringBuilder();
        boolean inQuotes = false;

        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                fields.add(currentField.toString());
                currentField = new StringBuilder();
            } else {
                currentField.append(c);
            }
        }
        fields.add(currentField.toString());

        return fields.toArray(new String[0]);
    }

    private Integer parseInteger(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}

