//
//  AuthManager.swift
//  HalalAI
//


import SwiftUI

@MainActor
protocol AuthManager {
    var authState: AuthState { get set }
    var currentUser: AuthResponse? { get set }
    var errorMessage: String? { get set }
    var isAuthenticated: Bool { get }
    var isGuest: Bool { get }
    var authToken: String? { get }
    func saveAuth(_ response: AuthResponse)
    func logout()
    func continueAsGuest()
    func refreshToken() async throws
}

@MainActor
@Observable
final class AuthManagerImpl: AuthManager {
    var authState: AuthState = .unauthenticated
    var currentUser: AuthResponse?
    var errorMessage: String?
    
    // TODO: Перенести хранение токена в Keychain для безопасности
    private let tokenKey = "HalalAI.authToken"
    private let userKey = "HalalAI.currentUser"
    private let guestKey = "HalalAI.isGuest"
    
    init() {
        loadStoredAuth()
    }
    
    // MARK: - Public Methods
    
    var isAuthenticated: Bool {
        return authState == .authenticated && currentUser != nil
    }

    var isGuest: Bool {
        return authState == .guest
    }
    
    var authToken: String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func saveAuth(_ response: AuthResponse) {
        currentUser = response
        UserDefaults.standard.set(response.token, forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: guestKey)

        if let userData = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }

        authState = .authenticated
        errorMessage = nil
    }

    func continueAsGuest() {
        authState = .guest
        UserDefaults.standard.set(true, forKey: guestKey)
    }
    
    func logout() {
        currentUser = nil
        cleanUserDefaults()
        authState = .unauthenticated
        errorMessage = nil
    }
    
    func refreshToken() async throws {
        guard let oldToken = authToken, !oldToken.isEmpty else {
            throw NSError(domain: "AuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Токен не найден"])
        }
        
        // Создаем временный AuthService для refresh
        let authService = AuthServiceImpl()
        let newAuthResponse = try await authService.refreshToken(oldToken)
        
        // Сохраняем новый токен
        saveAuth(newAuthResponse)
    }
    
    // MARK: - Private Methods
    
    private func loadStoredAuth() {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            cleanUserDefaults()
            authState = .unauthenticated
            return
        }

        guard let token = UserDefaults.standard.string(forKey: tokenKey),
              !token.isEmpty,
              let userData = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(AuthResponse.self, from: userData) else {
            authState = UserDefaults.standard.bool(forKey: guestKey) ? .guest : .unauthenticated
            return
        }

        currentUser = user
        authState = .authenticated
    }
    
    private func cleanUserDefaults() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: guestKey)
    }
}

