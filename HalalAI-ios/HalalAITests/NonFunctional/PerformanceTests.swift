//
//  PerformanceTests.swift
//  HalalAITests
//
//  4.4.3 Проверка производительности системы (iOS-клиент).
//
//  Измеряет время выполнения ключевых операций клиентского слоя
//  с замоканными сетевыми зависимостями.
//

import Foundation
import Testing
@testable import HalalAI

/// 4.4.3 Производительность — клиентские операции должны укладываться в SLA.
@MainActor
struct PerformanceTests {

    // MARK: - SLA

    private static let authSLA: Duration        = .milliseconds(500)
    private static let syncOpSLA: Duration      = .milliseconds(50)
    private static let aggregateSLA: Duration   = .milliseconds(2_500)

    // MARK: - AuthServiceImpl

    @Test("login с мок-клиентом укладывается в SLA 500 мс")
    func loginResponseTime() async throws {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        }
        let sut = AuthServiceImpl(networkClient: mockClient)

        let elapsed = try await ContinuousClock().measure {
            _ = try await sut.login(email: "a@b.com", password: "pass123")
        }

        #expect(elapsed < Self.authSLA,
                "login превысил SLA: \(elapsed) > \(Self.authSLA)")
    }

    @Test("register с мок-клиентом укладывается в SLA 500 мс")
    func registerResponseTime() async throws {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            AuthResponse(token: "tok", type: "Bearer", userId: 2, email: "new@b.com")
        }
        let sut = AuthServiceImpl(networkClient: mockClient)

        let elapsed = try await ContinuousClock().measure {
            _ = try await sut.register(email: "new@b.com", password: "pass123")
        }

        #expect(elapsed < Self.authSLA,
                "register превысил SLA: \(elapsed) > \(Self.authSLA)")
    }

    @Test("refreshToken с мок-клиентом укладывается в SLA 500 мс")
    func refreshTokenResponseTime() async throws {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            AuthResponse(token: "new-tok", type: "Bearer", userId: 1, email: "a@b.com")
        }
        let sut = AuthServiceImpl(networkClient: mockClient)

        let elapsed = try await ContinuousClock().measure {
            _ = try await sut.refreshToken("old-tok")
        }

        #expect(elapsed < Self.authSLA,
                "refreshToken превысил SLA: \(elapsed) > \(Self.authSLA)")
    }

    // MARK: - ChatServiceImpl

    @Test("sendMessage добавляет сообщение пользователя синхронно без задержки")
    func sendMessageIsSynchronouslyFast() {
        let (sut, authManager, mockClient) = makeChatSUT()
        authManager.authToken = "valid-tok"
        mockClient.sendRawHandler = { _ in throw NSError(domain: "test", code: 1) }

        let clock = ContinuousClock()
        let start = clock.now
        sut.sendMessage("Привет")
        let elapsed = clock.now - start

        #expect(sut.messages.count == 1)
        #expect(elapsed < Self.syncOpSLA,
                "sendMessage занял: \(elapsed) > \(Self.syncOpSLA)")
    }

    @Test("clearChat выполняется мгновенно")
    func clearChatIsSynchronouslyFast() {
        let (sut, _, _) = makeChatSUT()
        sut.messages = [
            ChatMessage(role: .user, text: "Привет"),
            ChatMessage(role: .assistant, text: "Ответ"),
        ]

        let clock = ContinuousClock()
        let start = clock.now
        sut.clearChat()
        let elapsed = clock.now - start

        #expect(sut.messages.isEmpty)
        #expect(elapsed < Self.syncOpSLA,
                "clearChat занял: \(elapsed) > \(Self.syncOpSLA)")
    }

    // MARK: - Повторные запросы

    @Test("5 последовательных login не деградируют по времени")
    func repeatedLoginRequests() async throws {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        }
        let sut = AuthServiceImpl(networkClient: mockClient)

        let elapsed = try await ContinuousClock().measure {
            for _ in 0..<5 {
                _ = try await sut.login(email: "a@b.com", password: "pass")
            }
        }

        #expect(elapsed < Self.aggregateSLA,
                "5 login-запросов заняли: \(elapsed) > \(Self.aggregateSLA)")
    }

    @Test("loadModels парсит ответ без заметной задержки")
    func loadModelsResponseTime() async {
        let (sut, _, mockClient) = makeChatSUT()
        let json = """
        {"default_model":"gpt-4","allowed_models":["gpt-4","gpt-3.5"]}
        """.data(using: .utf8)!

        mockClient.sendRawHandler = { _ in
            let resp = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (json, resp)
        }

        let elapsed = await ContinuousClock().measure {
            await sut.loadModels()
        }

        let modelsSLA: Duration = .milliseconds(200)
        #expect(elapsed < modelsSLA,
                "loadModels превысил SLA: \(elapsed) > \(modelsSLA)")
    }

    // MARK: - Helpers

    private func makeChatSUT() -> (ChatServiceImpl, MockAuthManager, MockNetworkClient) {
        let authManager = MockAuthManager()
        let settingsStore = ChatSettingsStore()
        let mockClient = MockNetworkClient()
        let sut = ChatServiceImpl(
            authManager: authManager,
            settingsStore: settingsStore,
            networkClient: mockClient
        )
        return (sut, authManager, mockClient)
    }
}
