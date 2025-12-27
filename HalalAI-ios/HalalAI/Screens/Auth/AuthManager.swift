//
//  AuthManager.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import Foundation
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var authState: AuthState = .unauthenticated
    @Published var currentUser: AuthResponse?
    @Published var errorMessage: String?
    
    private let tokenKey = "HalalAI.authToken"
    private let userKey = "HalalAI.currentUser"
    
    private init() {
        loadStoredAuth()
    }
    
    // MARK: - Public Methods
    
    var isAuthenticated: Bool {
        return authState == .authenticated && currentUser != nil
    }
    
    var authToken: String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func saveAuth(_ response: AuthResponse) {
        currentUser = response
        UserDefaults.standard.set(response.token, forKey: tokenKey)
        
        if let userData = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        
        authState = .authenticated
        errorMessage = nil
    }
    
    func logout() {
        currentUser = nil
        cleanUserDefaults()
        authState = .unauthenticated
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func loadStoredAuth() {
        guard let token = UserDefaults.standard.string(forKey: tokenKey),
              !token.isEmpty,
              let userData = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(AuthResponse.self, from: userData) else {
            authState = .unauthenticated
            return
        }
        
        currentUser = user
        authState = .authenticated
    }
    
    private func cleanUserDefaults() {
        UserDefaults.standard.dictionaryRepresentation().keys.forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
}

