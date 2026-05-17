//
//  ReliabilityTests.swift
//  HalalAITests
//
//  4.4.4 Проверка надёжности системы (iOS-клиент).
//
//  Проверяет устойчивость приложения к сетевым ошибкам, восстановление
//  после сбоев и корректную деградацию при недоступности бекенда.
//

import Foundation
import Testing
@testable import HalalAI

/// 4.4.4 Надёжность — приложение не падает при ошибках и корректно деградирует.
@MainActor
struct ReliabilityTests {

    // MARK: - AuthServiceImpl: устойчивость к ошибкам

    @Test("login при сетевой ошибке не вызывает краш, устанавливает errorMessage")
    func loginNetworkErrorDoesNotCrash() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in throw NetworkError.unknown(URLError(.notConnectedToInternet)) }
        let sut = AuthServiceImpl(networkClient: mockClient)

        do {
            _ = try await sut.login(email: "a@b.com", password: "pass")
            Issue.record("Expected error")
        } catch {
            #expect(sut.isLoading == false)
            #expect(sut.errorMessage != nil)
        }
    }

    @Test("register при недоступности сервера не вызывает краш")
    func registerServerUnavailableDoesNotCrash() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            throw NetworkError.serverError(statusCode: 503, data: Data())
        }
        let sut = AuthServiceImpl(networkClient: mockClient)

        do {
            _ = try await sut.register(email: "a@b.com", password: "pass123")
            Issue.record("Expected error")
        } catch {
            #expect(sut.isLoading == false)
        }
    }

    @Test("isLoading сбрасывается в false после любой ошибки")
    func isLoadingAlwaysResetAfterError() async {
        let mockClient = MockNetworkClient()
        let errors: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .serverError(statusCode: 500, data: Data()),
            .decodingError(NSError(domain: "", code: 0)),
            .unknown(NSError(domain: "", code: 0)),
        ]

        for networkError in errors {
            mockClient.sendHandler = { _ in throw networkError }
            let sut = AuthServiceImpl(networkClient: mockClient)
            _ = try? await sut.login(email: "a@b.com", password: "pass")
            #expect(sut.isLoading == false,
                    "isLoading не сброшен после ошибки: \(networkError)")
        }
    }

    @Test("3 последовательных сетевых ошибки не роняют AuthService")
    func repeatedNetworkFailuresDoNotCrash() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in throw NetworkError.unknown(URLError(.timedOut)) }
        let sut = AuthServiceImpl(networkClient: mockClient)

        for _ in 0..<3 {
            _ = try? await sut.login(email: "a@b.com", password: "pass")
        }

        #expect(sut.isLoading == false)
        #expect(sut.errorMessage != nil)
    }

    @Test("login после ошибки корректно восстанавливается при следующем успешном запросе")
    func loginRecoveryAfterFailure() async throws {
        let mockClient = MockNetworkClient()
        let sut = AuthServiceImpl(networkClient: mockClient)

        // первый запрос — ошибка
        mockClient.sendHandler = { _ in throw NetworkError.invalidURL }
        _ = try? await sut.login(email: "a@b.com", password: "pass")
        #expect(sut.errorMessage != nil)

        // второй запрос — успех
        mockClient.sendHandler = { _ in
            AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        }
        let result = try await sut.login(email: "a@b.com", password: "pass")
        #expect(result.token == "tok")
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    // MARK: - ChatServiceImpl: устойчивость к ошибкам

    @Test("sendMessage при отсутствии токена не вызывает краш")
    func sendMessageNoTokenDoesNotCrash() async throws {
        let (sut, authManager, mockClient) = makeChatSUT()
        authManager.authToken = nil
        mockClient.sendRawHandler = { _ in throw NSError(domain: "test", code: 1) }

        sut.sendMessage("Вопрос")
        try await Task.sleep(for: .milliseconds(150))

        #expect(!sut.messages.isEmpty)
        #expect(sut.chatState != .typing)
    }

    @Test("sendMessage при ошибке 500 выставляет connectionState = .disconnected")
    func sendMessageServerError() async throws {
        let (sut, authManager, mockClient) = makeChatSUT()
        authManager.authToken = "valid-tok"

        mockClient.sendRawHandler = { _ in
            let resp = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data("Internal Server Error".utf8), resp)
        }

        sut.sendMessage("Вопрос")
        try await Task.sleep(for: .milliseconds(200))

        #expect(sut.connectionState == .disconnected)
    }

    @Test("clearChat после серии ошибок сбрасывает состояние")
    func clearChatResetsStateAfterErrors() async throws {
        let (sut, authManager, mockClient) = makeChatSUT()
        authManager.authToken = "tok"
        mockClient.sendRawHandler = { _ in throw NSError(domain: "net", code: -1009) }

        sut.sendMessage("Вопрос 1")
        try await Task.sleep(for: .milliseconds(150))

        sut.clearChat()

        #expect(sut.messages.isEmpty)
        #expect(sut.chatState == .idle)
    }

    @Test("loadModels при ошибке не падает и сохраняет пустой список")
    func loadModelsErrorDoesNotCrash() async {
        let (sut, _, mockClient) = makeChatSUT()
        mockClient.sendRawHandler = { _ in throw NSError(domain: "test", code: 1) }

        await sut.loadModels()

        #expect(sut.availableModels.isEmpty)
        #expect(sut.chatState == .idle)
    }

    // MARK: - AuthManager: стабильность состояния

    @Test("logout после нескольких saveAuth корректно сбрасывает состояние")
    func logoutAfterMultipleSaveAuthIsClean() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager = AuthManagerImpl()
        for i in 1...3 {
            manager.saveAuth(
                AuthResponse(token: "tok-\(i)", type: "Bearer", userId: Int64(i), email: "u\(i)@b.com")
            )
        }

        manager.logout()

        #expect(manager.authState == .unauthenticated)
        #expect(manager.currentUser == nil)
        #expect(manager.authToken == nil)
        #expect(manager.isAuthenticated == false)
    }

    @Test("continueAsGuest и затем saveAuth переключает в authenticated")
    func guestToAuthenticatedTransition() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager = AuthManagerImpl()
        manager.continueAsGuest()
        #expect(manager.isGuest == true)

        manager.saveAuth(
            AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        )
        #expect(manager.isAuthenticated == true)
        #expect(manager.isGuest == false)
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

    private func cleanupUserDefaults() {
        ["HalalAI.authToken", "HalalAI.currentUser", "HalalAI.isGuest"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
}
