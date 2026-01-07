//
//  ChatService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import Foundation
import Combine

@MainActor
protocol ChatService: ObservableObject {
    var messages: [ChatMessage] { get set }
    var chatState: ChatState { get set }
    var connectionState: ConnectionState { get set }
    var userApiKey: String { get set }
    var remoteModel: String { get set }
    var maxTokens: Int { get set }
    var availableModels: [String] { get set }
    var defaultRemoteModel: String { get set }
    func loadModels() async
    func sendMessage(_ text: String)
    func retryLastMessage()
    func clearChat()
}

@MainActor
@Observable
class ChatServiceImpl: ChatService {
    // MARK: - public
    var messages: [ChatMessage] = []
    var chatState: ChatState = .idle
    var connectionState: ConnectionState = .connected
    var userApiKey: String = "" {
        didSet {
            UserDefaults.standard.set(userApiKey, forKey: apiKeyDefaultsKey)
        }
    }
    var remoteModel: String = "" {
        didSet {
            UserDefaults.standard.set(remoteModel, forKey: remoteModelDefaultsKey)
        }
    }
    var maxTokens: Int = 2048 {
        didSet {
            let clamped = max(16, min(maxTokens, 6144))
            if clamped != maxTokens {
                maxTokens = clamped
                return
            }
            UserDefaults.standard.set(maxTokens, forKey: maxTokensDefaultsKey)
        }
    }
    
    var availableModels: [String] = []
    var defaultRemoteModel: String = ""
    
    // MARK: - private
    private var cancellables = Set<AnyCancellable>()
    private var isSending = false 
    private var lastSendAt: Date?
    private var systemPrompt: String? = nil
    private var configLoaded = true
    
    private let defaultSystemPrompt = """
    Ты — HalalAI, умный исламский ассистент, специализирующийся на вопросах халяль, исламских принципах, Коране и исламском образе жизни. Твоя задача — давать точные, полезные и основанные на исламских источниках ответы. Всегда отвечай на русском языке, используй исламские термины (халяль, харам, сунна и т.д.) и будь уважительным и терпеливым. Если вопрос не связан с исламом, вежливо направь разговор в нужное русло. Отвечай кратко, но информативно.
    """
    
    private let backendURL: String = {
        #if DEBUG
        return "http://localhost:8080"
        #else
        // TODO: Заменить на production URL
        return "https://your-production-url.com"
        #endif
    }()
    
    private var authManager: any AuthManager
    // URLSession для запросов
    private var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    private let apiKeyDefaultsKey = "HalalAI.userApiKey"
    private let remoteModelDefaultsKey = "HalalAI.remoteModel"
    private let maxTokensDefaultsKey = "HalalAI.maxTokens"
    
    init(authManager: any AuthManager) {
        self.authManager = authManager
        self.userApiKey = UserDefaults.standard.string(forKey: apiKeyDefaultsKey) ?? ""
        self.remoteModel = UserDefaults.standard.string(forKey: remoteModelDefaultsKey) ?? ""
        let savedMax = UserDefaults.standard.integer(forKey: maxTokensDefaultsKey)
        self.maxTokens = savedMax == 0 ? 2048 : savedMax
        self.systemPrompt = defaultSystemPrompt
        self.configLoaded = true
    }
    
    // MARK: - Public Methods
    func loadModels() async {
        guard let url = URL(string: "\(backendURL)/api/models") else {
            print("⚠️ Неверный URL для моделей")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("⚠️ Ошибка загрузки моделей: \(String(data: data, encoding: .utf8) ?? "nil")")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("⚠️ Неверный формат JSON моделей")
                return
            }
            let defaultModel = (json["default_model"] as? String) ?? ""
            var allowed = (json["allowed_models"] as? [String]) ?? []
            if allowed.isEmpty, !defaultModel.isEmpty {
                allowed = [defaultModel]
            }
            // Если текущее remoteModel не из списка и есть список, сбрасываем на default для Picker
            let currentModel = self.remoteModel.trimmingCharacters(in: .whitespacesAndNewlines)
            await MainActor.run {
                self.defaultRemoteModel = defaultModel
                self.availableModels = allowed
                if !allowed.isEmpty {
                    if currentModel.isEmpty, !defaultModel.isEmpty {
                        self.remoteModel = defaultModel
                    } else if !currentModel.isEmpty, !allowed.contains(currentModel) {
                        self.remoteModel = defaultModel.isEmpty ? allowed.first ?? "" : defaultModel
                    }
                } else if currentModel.isEmpty, !defaultModel.isEmpty {
                    self.remoteModel = defaultModel
                }
            }
            print("✅ Модели загружены: default=\(defaultModel), count=\(allowed.count)")
        } catch {
            print("⚠️ Ошибка при загрузке моделей: \(error.localizedDescription)")
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // Защита от зависания: если предыдущее зависло >15 сек, разблокируем отправку
        if isSending, let last = lastSendAt, Date().timeIntervalSince(last) > 15 {
            isSending = false
            print("⚠️ sendMessage: предыдущий запрос завис >15с, сбрасываем isSending")
        }
        guard !isSending else {
            print("⚠️ sendMessage: блокируем отправку, предыдущий запрос еще обрабатывается")
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
        lastSendAt = Date()
        
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
        
        defer { isSending = false }
        
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
        var requestBody: [String: Any] = [
            "messages": messagesToSend,
            "max_tokens": maxTokens
        ]
        
        let trimmedKey = userApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            requestBody["api_key"] = trimmedKey
        }
        let trimmedModel = remoteModel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedModel.isEmpty {
            requestBody["remote_model"] = trimmedModel
        }
        
        print("➡️ Sending to backend \(backendURL)/api/chat")
        print("   messages=\(messagesToSend.count), max_tokens=\(maxTokens), api_key=\(!trimmedKey.isEmpty), remote_model=\(trimmedModel.isEmpty ? "none" : trimmedModel)")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            await handleError("Ошибка формирования запроса", userMessage: userMessage)
            return
        }
        
        // Создаем запрос
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        // Добавляем токен авторизации, если он есть
        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
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
                print("❌ Backend error status=\(httpResponse.statusCode), body=\(errorMessage)")
                await handleError("Ошибка сервера (\(httpResponse.statusCode)): \(errorMessage)", userMessage: userMessage)
                return
            }
            
            // Парсим ответ
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["reply"] as? String else {
                print("❌ Wrong JSON format: \(String(data: data, encoding: .utf8) ?? "nil")")
                await handleError("Неверный формат ответа от сервера", userMessage: userMessage)
                return
            }
        
            let usedRemote = json["used_remote"] as? Bool ?? false
            let modelInfo = json["model"] as? String
            let remoteError = json["remote_error"] as? String
            let trimmedKey = userApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            print("✅ Backend ok. used_remote=\(usedRemote), model=\(modelInfo ?? "nil"), remote_error=\(remoteError ?? "nil")")
            
            // Предупреждение, если ключ не принят и произошел fallback
            if !usedRemote, !trimmedKey.isEmpty {
                var warning = "Ваш API ключ не принят, используется локальная модель. Ответ может быть менее точным."
                if let remoteError = remoteError, !remoteError.isEmpty {
                    warning += " Детали: \(remoteError)"
                }
                let warnMessage = ChatMessage(role: .assistant, text: warning, model: nil)
                messages.append(warnMessage)
            }
            
            // Успешный ответ: добавляем ответ AI (сообщение пользователя уже в истории)
            let aiMessage = ChatMessage(role: .assistant, text: reply, model: modelInfo)
            messages.append(aiMessage)
            
            chatState = .idle
            connectionState = .connected
            isSending = false
            lastSendAt = nil
            
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
        lastSendAt = nil
    }
}
