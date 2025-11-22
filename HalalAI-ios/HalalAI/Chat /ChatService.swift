//
//  ChatService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import Foundation
import Combine

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var messages: [ChatMessage] = []
    @Published var chatState: ChatState = .idle
    @Published var connectionState: ConnectionState = .connected
    
    private var cancellables = Set<AnyCancellable>()
    private var isSending = false  // Защита от спама
    private var systemPrompt: String? = nil  // Системный промпт из конфига
    private var configLoaded = false  // Флаг загрузки конфига
    
    private let backendURL: String = {
        #if DEBUG
        return "http://localhost:8080"
        #else
        // TODO: Заменить на production URL
        return "https://your-production-url.com"
        #endif
    }()
    
    // URLSession для запросов
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    
    private init() {
        // Загружаем конфиг при инициализации
        Task {
            await loadConfig()
        }
    }
    
    // MARK: - Public Methods
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Защита от спама: не позволяем отправлять сообщения подряд
        guard !isSending else {
            print("⚠️ Попытка отправить сообщение во время обработки предыдущего")
            return
        }
        
        // Ждем загрузки конфига перед отправкой первого сообщения
        if !configLoaded {
            chatState = .typing
            connectionState = .connecting
            Task {
                await loadConfig()
                // После загрузки конфига отправляем сообщение
                let userMessage = ChatMessage(role: .user, text: text)
                // Добавляем сообщение пользователя сразу, чтобы оно отображалось
                messages.append(userMessage)
                await sendRequestToBackend(userMessage: userMessage, isRetry: false)
            }
            return
        }
        
        // Создаем сообщение пользователя
        let userMessage = ChatMessage(role: .user, text: text)
        
        // Добавляем сообщение пользователя сразу, чтобы оно сразу отображалось в чате
        messages.append(userMessage)
        
        // Устанавливаем состояние "печатает"
        chatState = .typing
        connectionState = .connecting
        isSending = true
        
        // Отправляем запрос к бекенду
        Task {
            await sendRequestToBackend(userMessage: userMessage, isRetry: false)
        }
    }
    
    func retryLastMessage() {
        guard !isSending else { return }
        
        // Находим последнее сообщение пользователя и ответ AI
        guard let lastUserIndex = messages.lastIndex(where: { $0.role == .user }) else { return }
        
        // Удаляем все сообщения после последнего вопроса пользователя (включая ответ AI)
        let lastUserMessage = messages[lastUserIndex]
        messages.removeSubrange((lastUserIndex + 1)..<messages.count)
        
        chatState = .typing
        connectionState = .connecting
        isSending = true
        
        Task {
            await sendRequestToBackend(userMessage: lastUserMessage, isRetry: true)
        }
    }
    
    func clearChat() {
        messages.removeAll()
        chatState = .idle
        isSending = false
        // Конфиг остается загруженным, системный промпт будет добавлен при следующем сообщении
    }
    
    // MARK: - Private Methods
    
    private func loadConfig() async {
        guard let url = URL(string: "\(backendURL)/api/config") else {
            print("⚠️ Неверный URL для загрузки конфига")
            configLoaded = true  // Помечаем как загруженный, чтобы не блокировать
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("⚠️ Ошибка загрузки конфига")
                configLoaded = true
                return
            }
            
            // Декодируем JSON с правильной кодировкой UTF-8
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let prompt = json["systemPrompt"] as? String else {
                print("⚠️ Неверный формат конфига")
                // Пробуем декодировать как UTF-8 строку для отладки
                if let debugString = String(data: data, encoding: .utf8) {
                    print("Полученные данные: \(debugString.prefix(200))")
                }
                configLoaded = true
                return
            }
            
            systemPrompt = prompt
            configLoaded = true
            print("✅ Конфиг загружен, системный промпт получен (длина: \(prompt.count) символов)")
            
        } catch {
            print("⚠️ Ошибка при загрузке конфига: \(error.localizedDescription)")
            configLoaded = true  // Помечаем как загруженный, чтобы не блокировать
        }
    }
    
    private func sendRequestToBackend(userMessage: ChatMessage, isRetry: Bool = false) async {
        guard let url = URL(string: "\(backendURL)/api/chat") else {
            await handleError("Неверный URL бекенда", userMessage: userMessage)
            return
        }
        
        // Формируем историю сообщений для отправки
        var messagesToSend: [[String: String]] = []
        
        // Всегда добавляем системный промпт первым сообщением, если он загружен
        if let prompt = systemPrompt, !prompt.isEmpty {
            messagesToSend.append([
                "role": "system",
                "content": prompt
            ])
        }
        
        // Добавляем все существующие сообщения (включая только что добавленное сообщение пользователя)
        for msg in messages {
            messagesToSend.append([
                "role": msg.role.rawValue,
                "content": msg.text
            ])
        }
        
        // Формируем тело запроса
        let requestBody: [String: Any] = [
            "messages": messagesToSend
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            await handleError("Ошибка формирования запроса", userMessage: userMessage)
            return
        }
        
        // Создаем запрос
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        request.timeoutInterval = 300 // 5 минут для генерации ответа
        
        do {
            connectionState = .connecting
            
            // Отправляем запрос
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await handleError("Неверный ответ от сервера", userMessage: userMessage)
                return
            }
            
            // Проверяем статус ответа
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Ошибка сервера"
                await handleError("Ошибка сервера (\(httpResponse.statusCode)): \(errorMessage)", userMessage: userMessage)
                return
            }
            
            // Парсим ответ
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let reply = json["reply"] as? String else {
                await handleError("Неверный формат ответа от сервера", userMessage: userMessage)
                return
            }
            
            // Успешный ответ: добавляем только ответ AI (сообщение пользователя уже в истории)
            let aiMessage = ChatMessage(role: .assistant, text: reply)
        messages.append(aiMessage)
        
        chatState = .idle
            connectionState = .connected
            isSending = false
            
        } catch {
            await handleError("Ошибка сети: \(error.localizedDescription)", userMessage: userMessage)
        }
    }
    
    private func handleError(_ message: String, userMessage: ChatMessage) async {
        let errorMessage = ChatMessage(role: .assistant, text: "У нас что-то сломалось, попробуйте позже или повторите попытку.")
        messages.append(errorMessage)
        
        chatState = .error(message)
        connectionState = .disconnected
        isSending = false
        
    }
}
