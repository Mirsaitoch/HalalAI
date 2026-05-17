//
//  SecurityTests.swift
//  HalalAITests
//
//  4.4.5 Проверка безопасности системы (iOS-клиент).
//
//  Проверяет жизненный цикл токена, входную валидацию, защиту
//  от несанкционированного доступа и корректность security-границ.
//

import Foundation
import Testing
@testable import HalalAI

/// 4.4.5 Безопасность — токен, доступ и входные данные обрабатываются корректно.
@MainActor
struct SecurityTests {

    // MARK: - Жизненный цикл токена

    @Test("authToken nil до аутентификации")
    func authTokenNilBeforeLogin() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager = AuthManagerImpl()
        #expect(manager.authToken == nil)
    }

    @Test("authToken устанавливается после saveAuth")
    func authTokenSetAfterSaveAuth() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager = AuthManagerImpl()
        manager.saveAuth(
            AuthResponse(token: "secret-token-xyz", type: "Bearer", userId: 1, email: "a@b.com")
        )

        #expect(manager.authToken == "secret-token-xyz")
    }

    @Test("authToken обнуляется после logout")
    func authTokenClearedAfterLogout() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager = AuthManagerImpl()
        manager.saveAuth(
            AuthResponse(token: "secret-token", type: "Bearer", userId: 1, email: "a@b.com")
        )
        manager.logout()

        #expect(manager.authToken == nil)
    }

    @Test("currentUser обнуляется после logout")
    func currentUserClearedAfterLogout() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager = AuthManagerImpl()
        manager.saveAuth(
            AuthResponse(token: "tok", type: "Bearer", userId: 99, email: "private@b.com")
        )
        manager.logout()

        #expect(manager.currentUser == nil)
        #expect(manager.isAuthenticated == false)
    }

    @Test("Гостевой режим не устанавливает authToken")
    func guestModeHasNoAuthToken() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager = AuthManagerImpl()
        manager.continueAsGuest()

        #expect(manager.authToken == nil)
        #expect(manager.isAuthenticated == false)
    }

    @Test("После logout повторная загрузка не восстанавливает токен")
    func logoutPreventsTokenRestorationOnReload() {
        cleanupUserDefaults()
        defer { cleanupUserDefaults() }

        let manager1 = AuthManagerImpl()
        manager1.saveAuth(
            AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        )
        manager1.logout()

        let manager2 = AuthManagerImpl()
        #expect(manager2.authToken == nil)
        #expect(manager2.authState == .unauthenticated)
    }

    // MARK: - Защита от несанкционированного доступа

    @Test("sendMessage без токена не отправляет запрос к API")
    func sendMessageWithoutTokenDoesNotCallApi() async throws {
        let authManager = MockAuthManager()
        authManager.authToken = nil

        let mockClient = MockNetworkClient()
        var apiCallCount = 0
        mockClient.sendRawHandler = { _ in
            apiCallCount += 1
            throw NSError(domain: "test", code: 1)
        }

        let sut = ChatServiceImpl(
            authManager: authManager,
            settingsStore: ChatSettingsStore(),
            networkClient: mockClient
        )

        sut.sendMessage("Секретный вопрос")
        try await Task.sleep(for: .milliseconds(200))

        // Запрос к API не должен быть отправлен без токена
        #expect(apiCallCount == 0,
                "API был вызван \(apiCallCount) раз(а) без токена аутентификации")
    }

    @Test("sendMessage с токеном отправляет Authorization заголовок")
    func sendMessageWithTokenCallsApi() async throws {
        let authManager = MockAuthManager()
        authManager.authToken = "valid-token"

        let mockClient = MockNetworkClient()
        var capturedRequest: (any APIRequest)?
        mockClient.sendRawHandler = { req in
            capturedRequest = req
            throw NSError(domain: "test", code: 1) // прерываем, нас интересует только факт вызова
        }

        let sut = ChatServiceImpl(
            authManager: authManager,
            settingsStore: ChatSettingsStore(),
            networkClient: mockClient
        )

        sut.sendMessage("Вопрос")
        try await Task.sleep(for: .milliseconds(200))

        #expect(capturedRequest != nil, "API должен быть вызван с токеном")
        #expect(capturedRequest?.token == "valid-token")
    }

    // MARK: - Входная валидация

    @Test("email обрезается от пробелов перед отправкой")
    func emailIsTrimmedBeforeSend() async throws {
        let mockClient = MockNetworkClient()
        var capturedEmail: String?

        mockClient.sendHandler = { req in
            if let loginReq = req as? LoginAPIRequest,
               let loginBody = loginReq.body as? LoginRequest {
                capturedEmail = loginBody.email
            }
            return AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        }

        let sut = AuthServiceImpl(networkClient: mockClient)
        _ = try await sut.login(email: "  a@b.com  ", password: "pass")

        #expect(capturedEmail == "a@b.com",
                "email не был обрезан: \"\(capturedEmail ?? "nil")\"")
    }

    @Test("пустой email не отправляет запрос через LoginViewModel")
    func emptyEmailDoesNotCallService() async {
        let authService = MockAuthService()
        let authManager = MockAuthManager()
        let vm = LoginView.ViewModel(authManager: authManager, authService: authService)

        vm.email = ""
        vm.password = "password123"
        await vm.login()

        #expect(authService.loginCallCount == 0)
        #expect(vm.showError == true)
    }

    @Test("очень длинный email не вызывает краш при login")
    func veryLongEmailDoesNotCrash() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            throw NetworkError.serverError(statusCode: 400, data: Data())
        }
        let sut = AuthServiceImpl(networkClient: mockClient)
        let longEmail = String(repeating: "a", count: 10_000) + "@b.com"

        _ = try? await sut.login(email: longEmail, password: "pass")

        #expect(sut.isLoading == false)
    }

    @Test("спецсимволы в пароле не вызывают краш")
    func specialCharsInPasswordDoNotCrash() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            throw NetworkError.serverError(statusCode: 401, data: Data())
        }
        let sut = AuthServiceImpl(networkClient: mockClient)
        let specialPassword = "'; DROP TABLE users; --\u{0000}<script>alert('xss')</script>"

        _ = try? await sut.login(email: "a@b.com", password: specialPassword)

        #expect(sut.isLoading == false)
    }

    @Test("SQL-инъекция в email не вызывает краш")
    func sqlInjectionInEmailDoesNotCrash() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            throw NetworkError.serverError(statusCode: 400, data: Data())
        }
        let sut = AuthServiceImpl(networkClient: mockClient)

        _ = try? await sut.login(email: "' OR '1'='1", password: "pass")

        #expect(sut.isLoading == false)
    }

    // MARK: - ChatSettingsStore: защитные границы

    @Test("maxTokens ограничивается диапазоном [16, 6144]")
    func maxTokensIsClamped() {
        let store = ChatSettingsStore()

        store.maxTokens = 0
        #expect(store.maxTokens >= 16, "maxTokens не должен быть меньше 16")

        store.maxTokens = 999_999
        #expect(store.maxTokens <= 6144, "maxTokens не должен превышать 6144")
    }

    @Test("temperature ограничивается диапазоном [0.0, 2.0]")
    func temperatureIsClamped() {
        let store = ChatSettingsStore()

        store.temperature = -10.0
        #expect(store.temperature >= 0.0, "temperature не должна быть отрицательной")

        store.temperature = 100.0
        #expect(store.temperature <= 2.0, "temperature не должна превышать 2.0")
    }

    // MARK: - Helpers

    private func cleanupUserDefaults() {
        ["HalalAI.authToken", "HalalAI.currentUser", "HalalAI.isGuest"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
}
