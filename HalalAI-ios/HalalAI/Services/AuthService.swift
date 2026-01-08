//
//  AuthService.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import Foundation

@MainActor
protocol AuthService: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    func register(username: String, email: String, password: String) async throws -> AuthResponse
    func login(usernameOrEmail: String, password: String) async throws -> AuthResponse
    func refreshToken(_ oldToken: String) async throws -> AuthResponse
}

@MainActor
@Observable
class AuthServiceImpl: AuthService {
    var isLoading = false
    var errorMessage: String?
    
    private let backendURL: String = {
        #if DEBUG
        return "http://localhost:8080"
        #else
        // TODO: Заменить на production URL
        return "https://your-production-url.com"
        #endif
    }()
    
    private var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    
    init() {
        print("Создаем AuthServiceImpl")
    }
    
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
    
    func refreshToken(_ oldToken: String) async throws -> AuthResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(backendURL)/api/auth/refresh") else {
            throw AuthError.networkError("Неверный URL бекенда")
        }
        
        let requestBody = RefreshTokenRequest(token: oldToken)
        
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            throw AuthError.unknown("Ошибка формирования запроса")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError("Неверный ответ от сервера")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Успешное обновление токена
                guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
                    throw AuthError.unknown("Неверный формат ответа от сервера")
                }
                return authResponse
                
            case 400, 401:
                // Токен невалиден или истек
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.validationError(errorResponse.message)
                }
                throw AuthError.invalidCredentials
                
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

