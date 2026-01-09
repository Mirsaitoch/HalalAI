//
//  AuthModels.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import Foundation

// MARK: - Auth Models

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct LoginRequest: Codable {
    let usernameOrEmail: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let token: String
}

struct AuthResponse: Codable {
    let token: String
    let type: String
    let userId: Int64
    let username: String
    let email: String
}

struct ErrorResponse: Codable {
    let message: String
    let timestamp: String?
    let path: String?
}

// MARK: - Auth State

enum AuthState: Equatable {
    case authenticated
    case unauthenticated
    case loading
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case userAlreadyExists
    case networkError(String)
    case validationError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверное имя пользователя или пароль"
        case .userAlreadyExists:
            return "Пользователь с таким именем или email уже существует"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        case .validationError(let message):
            return "Ошибка валидации: \(message)"
        case .unknown(let message):
            return message
        }
    }
}
