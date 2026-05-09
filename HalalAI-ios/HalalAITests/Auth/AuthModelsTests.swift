//
//  AuthModelsTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct AuthModelsTests {

    // MARK: - Request Codable

    @Test("RegisterRequest encodes correctly")
    func registerRequestCodable() throws {
        let request = RegisterRequest(email: "test@test.com", password: "pass123")
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(RegisterRequest.self, from: data)
        #expect(decoded.email == "test@test.com")
        #expect(decoded.password == "pass123")
    }

    @Test("LoginRequest encodes correctly")
    func loginRequestCodable() throws {
        let request = LoginRequest(email: "user@mail.com", password: "secret")
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(LoginRequest.self, from: data)
        #expect(decoded.email == "user@mail.com")
        #expect(decoded.password == "secret")
    }

    // MARK: - AuthResponse

    @Test("AuthResponse decodes from JSON")
    func authResponseDecode() throws {
        let json = """
        {"token":"jwt.token.here","type":"Bearer","userId":42,"email":"user@test.com"}
        """
        let response = try JSONDecoder().decode(AuthResponse.self, from: Data(json.utf8))
        #expect(response.token == "jwt.token.here")
        #expect(response.type == "Bearer")
        #expect(response.userId == 42)
        #expect(response.email == "user@test.com")
    }

    // MARK: - ErrorResponse

    @Test("ErrorResponse decodes with optional fields")
    func errorResponseOptionalFields() throws {
        let json = """
        {"message":"Not found"}
        """
        let response = try JSONDecoder().decode(ErrorResponse.self, from: Data(json.utf8))
        #expect(response.message == "Not found")
        #expect(response.timestamp == nil)
        #expect(response.path == nil)
    }

    @Test("ErrorResponse decodes with all fields")
    func errorResponseAllFields() throws {
        let json = """
        {"message":"Error","timestamp":"2026-01-01","path":"/api/test"}
        """
        let response = try JSONDecoder().decode(ErrorResponse.self, from: Data(json.utf8))
        #expect(response.message == "Error")
        #expect(response.timestamp == "2026-01-01")
        #expect(response.path == "/api/test")
    }

    // MARK: - AuthState

    @Test("AuthState equality")
    func authStateEquality() {
        #expect(AuthState.authenticated == AuthState.authenticated)
        #expect(AuthState.unauthenticated != AuthState.loading)
        #expect(AuthState.guest == AuthState.guest)
    }

    // MARK: - AuthError

    @Test("AuthError descriptions are in Russian",
          arguments: [
            (AuthError.invalidCredentials, "Неверный email или пароль"),
            (AuthError.userAlreadyExists, "Пользователь с таким email уже существует")
          ])
    func authErrorDescriptions(error: AuthError, expected: String) {
        #expect(error.errorDescription == expected)
    }

    @Test("AuthError networkError includes message")
    func networkErrorDescription() {
        let error = AuthError.networkError("таймаут")
        #expect(error.errorDescription?.contains("таймаут") == true)
    }

    @Test("AuthError validationError includes message")
    func validationErrorDescription() {
        let error = AuthError.validationError("email невалиден")
        #expect(error.errorDescription?.contains("email невалиден") == true)
    }
}
