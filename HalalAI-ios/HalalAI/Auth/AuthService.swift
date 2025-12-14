//
//  AuthService.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import Foundation

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let backendURL: String = {
        #if DEBUG
        return "http://localhost:8080"
        #else
        // TODO: Заменить на production URL
        return "https://your-production-url.com"
        #endif
    }()
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(backendURL)/api/auth/register") else {
            throw AuthError.networkError("Неверный URL бекенда")
        }
        
        let requestBody = RegisterRequest(
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            throw AuthError.unknown("Ошибка формирования запроса")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError("Неверный ответ от сервера")
            }
            
            switch httpResponse.statusCode {
            case 201:
                // Успешная регистрация
                guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
                    throw AuthError.unknown("Неверный формат ответа от сервера")
                }
                return authResponse
                
            case 400:
                // Ошибка валидации или пользователь уже существует
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    if errorResponse.message.contains("уже существует") {
                        throw AuthError.userAlreadyExists
                    }
                    throw AuthError.validationError(errorResponse.message)
                }
                throw AuthError.validationError("Ошибка валидации данных")
                
            default:
                // Другие ошибки
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.unknown(errorResponse.message)
                }
                throw AuthError.networkError("Ошибка сервера (\(httpResponse.statusCode))")
            }
            
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            let networkError = AuthError.networkError(error.localizedDescription)
            errorMessage = networkError.errorDescription
            throw networkError
        }
    }
    
    func login(usernameOrEmail: String, password: String) async throws -> AuthResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(backendURL)/api/auth/login") else {
            throw AuthError.networkError("Неверный URL бекенда")
        }
        
        let requestBody = LoginRequest(
            usernameOrEmail: usernameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            throw AuthError.unknown("Ошибка формирования запроса")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError("Неверный ответ от сервера")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Успешный вход
                guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
                    throw AuthError.unknown("Неверный формат ответа от сервера")
                }
                return authResponse
                
            case 401:
                throw AuthError.invalidCredentials
                
            case 400:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.validationError(errorResponse.message)
                }
                throw AuthError.validationError("Ошибка валидации данных")
                
            default:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.unknown(errorResponse.message)
                }
                throw AuthError.networkError("Ошибка сервера (\(httpResponse.statusCode))")
            }
            
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            let networkError = AuthError.networkError(error.localizedDescription)
            errorMessage = networkError.errorDescription
            throw networkError
        }
    }
}

