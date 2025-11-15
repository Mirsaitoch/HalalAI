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
        // Устанавливаем таймауты для запросов к LLM сервису
        // Генерация может занять время, поэтому ставим большой таймаут
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000); // 5 секунд на подключение
        factory.setReadTimeout(300000); // 5 минут на чтение (генерация может быть долгой)
        
        return builder
                .requestFactory(() -> factory)
                .build();
    }
}

