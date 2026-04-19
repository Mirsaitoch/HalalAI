//
//  AuthService.swift
//  HalalAI
//


import Foundation

@MainActor
protocol AuthService {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    func register(email: String, password: String) async throws -> AuthResponse
    func login(email: String, password: String) async throws -> AuthResponse
    func refreshToken(_ oldToken: String) async throws -> AuthResponse
}

@MainActor
@Observable
final class AuthServiceImpl: AuthService {
    var isLoading = false
    var errorMessage: String?

    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    func register(email: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        return try await performRequest(RegisterAPIRequest(body: body))
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        return try await performRequest(LoginAPIRequest(body: body))
    }

    func refreshToken(_ oldToken: String) async throws -> AuthResponse {
        let body = RefreshTokenRequest(token: oldToken)
        return try await performRequest(RefreshTokenAPIRequest(body: body))
    }

    // MARK: - Private

    private func performRequest<R: APIRequest>(
        _ request: R
    ) async throws -> AuthResponse where R.Response == AuthResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            return try await networkClient.send(request)
        } catch {
            let authError = mapToAuthError(error)
            errorMessage = authError.errorDescription
            throw authError
        }
    }

    /// Маппинг NetworkError → AuthError с сохранением бизнес-логики статус-кодов
    private func mapToAuthError(_ error: NetworkError) -> AuthError {
        switch error {
        case .invalidURL:
            return .networkError("Неверный URL бекенда")

        case .invalidResponse:
            return .networkError("Неверный ответ от сервера")

        case .serverError(let statusCode, let data):
            switch statusCode {
            case 400:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    if errorResponse.message.contains("уже существует") {
                        return .userAlreadyExists
                    }
                    return .validationError(errorResponse.message)
                }
                return .validationError("Ошибка валидации данных")

            case 401:
                return .invalidCredentials

            default:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    return .unknown(errorResponse.message)
                }
                return .networkError("Ошибка сервера (\(statusCode))")
            }

        case .decodingError:
            return .unknown("Неверный формат ответа от сервера")

        case .unknown(let underlying):
            return .networkError(underlying.localizedDescription)
        }
    }
}
