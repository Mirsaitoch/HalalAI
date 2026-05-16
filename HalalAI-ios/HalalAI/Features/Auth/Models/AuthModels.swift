//
//  AuthModels.swift
//  HalalAI
//


import Foundation

// MARK: - Auth Models

struct RegisterRequest: Codable {
    let email: String
    let password: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let token: String
}

struct AuthResponse: Codable {
    let token: String
    let type: String
    let userId: Int64
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
    case guest
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
            return "Неверный email или пароль"
        case .userAlreadyExists:
            return "Пользователь с таким email уже существует"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        case .validationError(let message):
            return "Ошибка валидации: \(message)"
        case .unknown(let message):
            return message
        }
    }
}
