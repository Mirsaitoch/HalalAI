//
//  ChatService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import Foundation

@MainActor
protocol ChatService {
    var messages: [ChatMessage] { get set }
    var chatState: ChatState { get set }
    var connectionState: ConnectionState { get set }
    var userApiKey: String { get set }
    var remoteModel: String { get set }
    var maxTokens: Int { get set }
    var temperature: Double { get set }
    var useRag: Bool { get set }
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

    var userApiKey: String {
        get { settingsStore.userApiKey }
        set { settingsStore.userApiKey = newValue }
    }
    var remoteModel: String {
        get { settingsStore.remoteModel }
        set { settingsStore.remoteModel = newValue }
    }
    var maxTokens: Int {
        get { settingsStore.maxTokens }
        set { settingsStore.maxTokens = newValue }
    }
    var temperature: Double {
        get { settingsStore.temperature }
        set { settingsStore.temperature = newValue }
    }
    var useRag: Bool {
        get { settingsStore.useRag }
        set { settingsStore.useRag = newValue }
    }

    var availableModels: [String] = []
    var defaultRemoteModel: String = ""

    // MARK: - Private

    private var isSending = false
    private var lastSendAt: Date?
    private let settingsStore: ChatSettingsStore
    private let authManager: AuthManager
    private let networkClient: NetworkClient

    init(authManager: AuthManager, settingsStore: ChatSettingsStore, networkClient: NetworkClient = NetworkClient()) {
        self.authManager = authManager
        self.settingsStore = settingsStore
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    func loadModels() async {
        do {
            let (data, response) = try await networkClient.sendRaw(ModelsAPIRequest())

            guard response.statusCode == 200 else {
                print("⚠️ Ошибка загрузки моделей: \(String(data: data, encoding: .utf8) ?? "nil")")
                return
            }

            let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)

            let defaultModel = modelsResponse.defaultModel ?? ""
            var allowed = modelsResponse.allowedModels ?? []
            if allowed.isEmpty, !defaultModel.isEmpty {
                allowed = [defaultModel]
            }

            let currentModel = remoteModel.trimmingCharacters(in: .whitespacesAndNewlines)
            self.defaultRemoteModel = defaultModel
            self.availableModels = allowed
            if !allowed.isEmpty, currentModel.isEmpty, !defaultModel.isEmpty {
                self.remoteModel = defaultModel
            }
            print("✅ Модели загружены: default=\(defaultModel), count=\(allowed.count)")
        } catch {
            print("⚠️ Ошибка при загрузке моделей: \(error)")
        }
    }

    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if isSending, let last = lastSendAt, Date.now.timeIntervalSince(last) > 15 {
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
        lastSendAt = Date.now

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
        defer { isSending = false }

        let messagesToSend = messages.map { ChatMessageDTO(role: $0.role.rawValue, content: $0.text) }

        let chatRequest = ChatRequest(
            messages: messagesToSend,
            maxTokens: maxTokens,
            temperature: temperature,
            useRag: useRag,
            apiKey: userApiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            remoteModel: remoteModel.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        guard let token = authManager.authToken else {
            await handleError("Нет токена авторизации")
            return
        }

        do {
            connectionState = .connecting
            let (data, response) = try await networkClient.sendRaw(
                ChatAPIRequest(body: chatRequest, token: token)
            )

            guard response.statusCode == 200 else {
                if response.statusCode == 401 || response.statusCode == 403 {
                    do {
                        try await authManager.refreshToken()
                        return await sendRequestToBackend(userMessage: userMessage, isRetry: isRetry)
                    } catch {
                        authManager.logout()
                        await handleError("Сессия истекла. Пожалуйста, войдите снова.")
                        return
                    }
                }

                let errorMessage = String(data: data, encoding: .utf8) ?? "Ошибка сервера"
                await handleError("Ошибка сервера (\(response.statusCode)): \(errorMessage)")
                return
            }

            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

            let aiMessage = ChatMessage(role: .assistant, text: chatResponse.reply)
            messages.append(aiMessage)

            chatState = .idle
            connectionState = .connected
            isSending = false
            lastSendAt = nil
        } catch {
            await handleError("Ошибка сети: \(error)")
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

// MARK: - Private API

private struct ModelsAPIRequest: APIRequest {
    typealias Response = ModelsResponse

    let endpoint = Endpoint.models
    let timeout: TimeInterval = 15
}

private struct ChatAPIRequest: APIRequest {
    typealias Response = ChatResponse

    let endpoint = Endpoint.chat
    let body: (any Encodable & Sendable)?
    let token: String?
    let timeout: TimeInterval = 300

    init(body: ChatRequest, token: String) {
        self.body = body
        self.token = token
    }
}

// MARK: - Private DTO

private struct ChatMessageDTO: Codable, Sendable {
    let role: String
    let content: String
}

private struct ChatRequest: Codable, Sendable {
    let messages: [ChatMessageDTO]
    let maxTokens: Int
    let temperature: Double
    let useRag: Bool
    let apiKey: String
    let remoteModel: String

    enum CodingKeys: String, CodingKey {
        case messages
        case maxTokens = "max_tokens"
        case temperature
        case useRag = "use_rag"
        case apiKey = "api_key"
        case remoteModel = "remote_model"
    }
}

private struct ChatResponse: Codable, Sendable {
    let reply: String
}

private struct ModelsResponse: Codable, Sendable {
    let defaultModel: String?
    let allowedModels: [String]?

    enum CodingKeys: String, CodingKey {
        case defaultModel = "default_model"
        case allowedModels = "allowed_models"
    }
}

