//
//  AuthServiceMapErrorTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct AuthServiceMapErrorTests {

    private let sut = AuthServiceImpl()

    // MARK: - invalidURL

    @Test("mapToAuthError maps invalidURL to networkError")
    func invalidURL() {
        let result = sut.mapToAuthError(.invalidURL)
        #expect(result == .networkError("Неверный URL бекенда"))
    }

    // MARK: - invalidResponse

    @Test("mapToAuthError maps invalidResponse to networkError")
    func invalidResponse() {
        let result = sut.mapToAuthError(.invalidResponse)
        #expect(result == .networkError("Неверный ответ от сервера"))
    }

    // MARK: - serverError 400

    @Test("mapToAuthError maps 400 with 'уже существует' to userAlreadyExists")
    func serverError400UserExists() throws {
        let body = ErrorResponse(message: "Пользователь уже существует", timestamp: nil, path: nil)
        let data = try JSONEncoder().encode(body)
        let result = sut.mapToAuthError(.serverError(statusCode: 400, data: data))
        #expect(result == .userAlreadyExists)
    }

    @Test("mapToAuthError maps 400 with other message to validationError")
    func serverError400Validation() throws {
        let body = ErrorResponse(message: "Email обязателен", timestamp: nil, path: nil)
        let data = try JSONEncoder().encode(body)
        let result = sut.mapToAuthError(.serverError(statusCode: 400, data: data))
        #expect(result == .validationError("Email обязателен"))
    }

    @Test("mapToAuthError maps 400 with unparseable body to generic validationError")
    func serverError400Unparseable() {
        let data = Data("not json".utf8)
        let result = sut.mapToAuthError(.serverError(statusCode: 400, data: data))
        #expect(result == .validationError("Ошибка валидации данных"))
    }

    // MARK: - serverError 401

    @Test("mapToAuthError maps 401 to invalidCredentials")
    func serverError401() {
        let data = Data()
        let result = sut.mapToAuthError(.serverError(statusCode: 401, data: data))
        #expect(result == .invalidCredentials)
    }

    // MARK: - serverError other

    @Test("mapToAuthError maps 500 with parseable body to unknown with message")
    func serverError500WithBody() throws {
        let body = ErrorResponse(message: "Internal error", timestamp: nil, path: nil)
        let data = try JSONEncoder().encode(body)
        let result = sut.mapToAuthError(.serverError(statusCode: 500, data: data))
        #expect(result == .unknown("Internal error"))
    }

    @Test("mapToAuthError maps 500 with unparseable body to networkError")
    func serverError500Unparseable() {
        let data = Data("bad".utf8)
        let result = sut.mapToAuthError(.serverError(statusCode: 500, data: data))
        #expect(result == .networkError("Ошибка сервера (500)"))
    }

    @Test("mapToAuthError maps 403 to networkError with status code")
    func serverError403() {
        let data = Data()
        let result = sut.mapToAuthError(.serverError(statusCode: 403, data: data))
        #expect(result == .networkError("Ошибка сервера (403)"))
    }

    // MARK: - decodingError

    @Test("mapToAuthError maps decodingError to unknown")
    func decodingError() {
        let underlying = NSError(domain: "decode", code: 1)
        let result = sut.mapToAuthError(.decodingError(underlying))
        #expect(result == .unknown("Неверный формат ответа от сервера"))
    }

    // MARK: - unknown

    @Test("mapToAuthError maps unknown to networkError with description")
    func unknownError() {
        let underlying = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        let result = sut.mapToAuthError(.unknown(underlying))
        #expect(result == .networkError("The Internet connection appears to be offline."))
    }
}

// MARK: - AuthError Equatable for testing

extension AuthError: Equatable {
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials):
            return true
        case (.userAlreadyExists, .userAlreadyExists):
            return true
        case (.networkError(let a), .networkError(let b)):
            return a == b
        case (.validationError(let a), .validationError(let b)):
            return a == b
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}
