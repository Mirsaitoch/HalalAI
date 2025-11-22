package com.halalai.backend.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import com.halalai.backend.model.ChatMessage;

/**
 * Сервис для управления историей разговоров
 * Хранит историю в HTTP сессии Spring
 */
@Service
public class ChatHistoryService {
    
    // Ключ для хранения истории в HTTP сессии
    private static final String SESSION_HISTORY_KEY = "chatHistory";
    
    // Максимальное количество сообщений в истории (чтобы не было слишком больших промптов)
    private static final int MAX_HISTORY_SIZE = 10; // Последние 10 сообщений (5 пар вопрос-ответ)
    
    // Максимальная длина одного сообщения (чтобы не было слишком длинных сообщений)
    private static final int MAX_MESSAGE_LENGTH = 2000;

    /**
     * Получает историю разговора из HTTP сессии
     */
    @SuppressWarnings("unchecked")
    private List<ChatMessage> getHistoryFromSession(jakarta.servlet.http.HttpSession session) {
        if (session == null) {
            return new ArrayList<>();
        }
        
        Object historyObj = session.getAttribute(SESSION_HISTORY_KEY);
        if (historyObj == null) {
            return new ArrayList<>();
        }
        
        try {
            return (List<ChatMessage>) historyObj;
        } catch (ClassCastException e) {
            // Если формат неверный, создаем новую историю
            session.removeAttribute(SESSION_HISTORY_KEY);
            return new ArrayList<>();
        }
    }

    /**
     * Сохраняет историю в HTTP сессию
     */
    private void saveHistoryToSession(jakarta.servlet.http.HttpSession session, List<ChatMessage> history) {
        if (session != null) {
            session.setAttribute(SESSION_HISTORY_KEY, history);
        }
    }

    /**
     * Добавляет сообщение пользователя в историю
     */
    public void addUserMessage(jakarta.servlet.http.HttpSession session, String message) {
        if (session == null) {
            return;
        }
        
        String truncatedMessage = truncateMessage(message);
        ChatMessage chatMessage = new ChatMessage("user", truncatedMessage, LocalDateTime.now());
        addMessage(session, chatMessage);
    }

    /**
     * Добавляет ответ ассистента в историю
     */
    public void addAssistantMessage(jakarta.servlet.http.HttpSession session, String message) {
        if (session == null) {
            return;
        }
        
        String truncatedMessage = truncateMessage(message);
        ChatMessage chatMessage = new ChatMessage("assistant", truncatedMessage, LocalDateTime.now());
        addMessage(session, chatMessage);
    }

    /**
     * Получает историю разговора для формирования контекста
     * Возвращает последние N сообщений (без текущего запроса)
     */
    public List<ChatMessage> getHistory(jakarta.servlet.http.HttpSession session) {
        if (session == null) {
            return List.of();
        }
        
        List<ChatMessage> history = getHistoryFromSession(session);
        if (history.isEmpty()) {
            return List.of();
        }
        
        // Возвращаем последние MAX_HISTORY_SIZE сообщений
        // Это будут только предыдущие сообщения, без текущего запроса
        int startIndex = Math.max(0, history.size() - MAX_HISTORY_SIZE);
        return new ArrayList<>(history.subList(startIndex, history.size()));
    }

    /**
     * Очищает историю для сессии
     */
    public void clearHistory(jakarta.servlet.http.HttpSession session) {
        if (session != null) {
            session.removeAttribute(SESSION_HISTORY_KEY);
        }
    }

    /**
     * Добавляет сообщение в историю с ограничением размера
     */
    private void addMessage(jakarta.servlet.http.HttpSession session, ChatMessage message) {
        List<ChatMessage> history = getHistoryFromSession(session);
        history.add(message);
        
        // Ограничиваем размер истории
        if (history.size() > MAX_HISTORY_SIZE * 2) {
            // Удаляем старые сообщения, оставляем только последние
            int startIndex = history.size() - MAX_HISTORY_SIZE;
            List<ChatMessage> recentHistory = new ArrayList<>(history.subList(startIndex, history.size()));
            history = recentHistory;
        }
        
        saveHistoryToSession(session, history);
    }

    /**
     * Обрезает сообщение если оно слишком длинное
     */
    private String truncateMessage(String message) {
        if (message == null) {
            return "";
        }
        if (message.length() > MAX_MESSAGE_LENGTH) {
            return message.substring(0, MAX_MESSAGE_LENGTH) + "... (сообщение обрезано)";
        }
        return message;
    }

    /**
     * Форматирует историю для промпта
     */
    public String formatHistoryForPrompt(List<ChatMessage> history) {
        if (history == null || history.isEmpty()) {
            return "";
        }
        
        StringBuilder sb = new StringBuilder();
        sb.append("\n=== Предыдущий контекст разговора ===\n");
        
        for (ChatMessage msg : history) {
            sb.append(msg.role().equals("user") ? "Пользователь: " : "Ассистент: ");
            sb.append(msg.content());
            sb.append("\n\n");
        }
        
        sb.append("=== Конец предыдущего контекста ===\n");
        return sb.toString();
    }
}

