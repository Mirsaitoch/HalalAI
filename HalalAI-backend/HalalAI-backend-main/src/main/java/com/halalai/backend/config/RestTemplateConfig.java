package com.halalai.backend.config;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestTemplateConfig {

    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        // Устанавливаем таймауты для запросов к LLM сервису.
        // Генерация ограничена сервером до 3 минут, поэтому читаем не дольше 3 минут.
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10000); // 10 секунд на подключение
        factory.setReadTimeout(180000); // 3 минуты на чтение ответа
        
        return builder
                .requestFactory(() -> factory)
                .build();
    }
}

