//
//  ChatService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import Foundation
import Combine

@MainActor
protocol ChatService {
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
final class ChatServiceImpl: ChatService {
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
    private var configLoaded = true
    
    private let backendURL: String = {
        #if DEBUG
        return "http://localhost:8080"
        #else
        // TODO: Заменить на production URL
        return "https://your-production-url.com"
        #endif
    }()
    
    private var authManager: AuthManager
    private var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    private let apiKeyDefaultsKey = "HalalAI.userApiKey"
    private let remoteModelDefaultsKey = "HalalAI.remoteModel"
    private let maxTokensDefaultsKey = "HalalAI.maxTokens"
    
    init(authManager: AuthManager) {
        print("Создаем ChatServiceImpl")
        self.authManager = authManager
        self.userApiKey = UserDefaults.standard.string(forKey: apiKeyDefaultsKey) ?? ""
        self.remoteModel = UserDefaults.standard.string(forKey: remoteModelDefaultsKey) ?? ""
        let savedMax = UserDefaults.standard.integer(forKey: maxTokensDefaultsKey)
        self.maxTokens = savedMax == 0 ? 2048 : savedMax
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
        request.setValue("application/json", forHTTPHeaderField: "Accept")
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
        if isSending, let last = lastSendAt, Date().timeIntervalSince(last) > 15 {
            isSending = false
            print("⚠️ sendMessage: предыдущий запрос завис >15с, сбрасываем isSending")
        }
        guard !isSending else {
            print("⚠️ sendMessage: блокируем отправку, предыдущий запрос еще обрабатывается")
            return
        }
        
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        
        chatState = .typing
        connectionState = .connecting
        isSending = true
        lastSendAt = Date()
        
        Task {
            await sendRequestToBackend(userMessage: userMessage, isRetry: false)
        }
    }
    
    func retryLastMessage() {
        guard !isSending else { return }
        
        guard let lastUserIndex = messages.lastIndex(where: { $0.role == .user }) else { return }
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
    }
    
    // MARK: - Private Methods
        
    private func sendRequestToBackend(userMessage: ChatMessage, isRetry: Bool = false) async {
        guard let url = URL(string: "\(backendURL)/api/chat") else {
            await handleError("Неверный URL бекенда")
            return
        }
        
        defer { isSending = false }
        
        var messagesToSend: [[String: String]] = []
        for msg in messages {
            messagesToSend.append([
                "role": msg.role.rawValue,
                "content": msg.text
            ])
        }
        
        var requestBody: [String: Any] = [
            "messages": messagesToSend,
            "max_tokens": maxTokens
        ]
        
        let trimmedKey = userApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = remoteModel.trimmingCharacters(in: .whitespacesAndNewlines)

        requestBody["api_key"] = trimmedKey
        requestBody["remote_model"] = trimmedModel

        print("➡️ Sending to backend \(backendURL)/api/chat")
        print("   messages=\(messagesToSend.count), max_tokens=\(maxTokens), api_key=\(!trimmedKey.isEmpty), remote_model=\(trimmedModel.isEmpty ? "none" : trimmedModel)")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            await handleError("Ошибка формирования запроса")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            await handleError("Нет токена авторизации")
        }
        
        request.httpBody = jsonData
        request.timeoutInterval = 300
        
        do {
            connectionState = .connecting
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await handleError("Неверный ответ от сервера")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    print("🔄 Токен истек (status=\(httpResponse.statusCode)), пытаемся обновить...")
                    
                    do {
                        try await authManager.refreshToken()
                        print("✅ Токен обновлен, повторяем запрос...")
                        return await sendRequestToBackend(userMessage: userMessage, isRetry: isRetry)
                    } catch {
                        print("❌ Не удалось обновить токен: \(error.localizedDescription)")
                        authManager.logout()
                        await handleError("Сессия истекла. Пожалуйста, войдите снова.")
                        return
                    }
                }
                
                let errorMessage = String(data: data, encoding: .utf8) ?? "Ошибка сервера"
                print("❌ Backend error status=\(httpResponse.statusCode), body=\(errorMessage)")
                await handleError("Ошибка сервера (\(httpResponse.statusCode)): \(errorMessage)")
                return
            }
            
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["reply"] as? String else {
                print("❌ Wrong JSON format: \(String(data: data, encoding: .utf8) ?? "nil")")
                await handleError("Неверный формат ответа от сервера")
                return
            }
        
            let usedRemote = json["used_remote"] as? Bool ?? false
            let modelInfo = json["model"] as? String
            let remoteError = json["remote_error"] as? String
            let trimmedKey = userApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            print("✅ Backend ok. used_remote=\(usedRemote), model=\(modelInfo ?? "nil"), remote_error=\(remoteError ?? "nil")")
            
            // Если у пользователя есть ключ, но он не сработал и используется локальная модель
            if !usedRemote, !trimmedKey.isEmpty {
                var warning = "Ваш API ключ не принят, используется локальная модель. Ответ может быть менее точным."
                if let remoteError = remoteError, !remoteError.isEmpty {
                    warning += "\nДетали: \(remoteError)"
                }
                let warnMessage = ChatMessage(role: .assistant, text: warning, model: nil)
                messages.append(warnMessage)
            }
            
            let aiMessage = ChatMessage(role: .assistant, text: reply, model: modelInfo)
            messages.append(aiMessage)
            
            chatState = .idle
            connectionState = .connected
            isSending = false
            lastSendAt = nil
        } catch {
            await handleError("Ошибка сети: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ message: String) async {
        let errorMessage = ChatMessage(role: .assistant, text: "У нас что-то сломалось, попробуйте позже или повторите попытку.")
        messages.append(errorMessage)
        
        chatState = .error(message)
        connectionState = .disconnected
        isSending = false
        lastSendAt = nil
    }
}
