//
//  AuthServiceImplTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct AuthServiceImplTests {

    // MARK: - Login

    @Test("login trims email and sends request")
    func loginSuccess() async throws {
        let mockClient = MockNetworkClient()
        let expectedResponse = AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        mockClient.sendHandler = { _ in expectedResponse }

        let sut = AuthServiceImpl(networkClient: mockClient)
        let result = try await sut.login(email: "  a@b.com  ", password: "pass123")

        #expect(result.token == "tok")
        #expect(result.email == "a@b.com")
        #expect(mockClient.sendCallCount == 1)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("login sets isLoading during request")
    func loginSetsLoading() async throws {
        let mockClient = MockNetworkClient()
        let sut = AuthServiceImpl(networkClient: mockClient)

        mockClient.sendHandler = { _ in
            #expect(sut.isLoading == true)
            return AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        }

        _ = try await sut.login(email: "a@b.com", password: "pass")
        #expect(sut.isLoading == false)
    }

    @Test("login maps NetworkError.invalidURL to AuthError.networkError")
    func loginInvalidURL() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in throw NetworkError.invalidURL }

        let sut = AuthServiceImpl(networkClient: mockClient)

        do {
            _ = try await sut.login(email: "a@b.com", password: "pass")
            Issue.record("Expected error")
        } catch {
            #expect(sut.errorMessage != nil)
            #expect(sut.isLoading == false)
        }
    }

    @Test("login maps 401 to invalidCredentials")
    func login401() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in
            throw NetworkError.serverError(statusCode: 401, data: Data())
        }

        let sut = AuthServiceImpl(networkClient: mockClient)

        do {
            _ = try await sut.login(email: "a@b.com", password: "wrong")
            Issue.record("Expected error")
        } catch let error as AuthError {
            #expect(error == .invalidCredentials)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Register

    @Test("register trims email and sends request")
    func registerSuccess() async throws {
        let mockClient = MockNetworkClient()
        let expectedResponse = AuthResponse(token: "new-tok", type: "Bearer", userId: 2, email: "new@b.com")
        mockClient.sendHandler = { _ in expectedResponse }

        let sut = AuthServiceImpl(networkClient: mockClient)
        let result = try await sut.register(email: " new@b.com ", password: "pass123")

        #expect(result.token == "new-tok")
        #expect(result.userId == 2)
    }

    @Test("register maps 400 'уже существует' to userAlreadyExists")
    func registerUserExists() async throws {
        let mockClient = MockNetworkClient()
        let body = try JSONEncoder().encode(ErrorResponse(message: "Пользователь уже существует", timestamp: nil, path: nil))
        mockClient.sendHandler = { _ in
            throw NetworkError.serverError(statusCode: 400, data: body)
        }

        let sut = AuthServiceImpl(networkClient: mockClient)

        do {
            _ = try await sut.register(email: "a@b.com", password: "pass")
            Issue.record("Expected error")
        } catch let error as AuthError {
            #expect(error == .userAlreadyExists)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - RefreshToken

    @Test("refreshToken sends old token and returns new response")
    func refreshTokenSuccess() async throws {
        let mockClient = MockNetworkClient()
        let expectedResponse = AuthResponse(token: "refreshed", type: "Bearer", userId: 1, email: "a@b.com")
        mockClient.sendHandler = { _ in expectedResponse }

        let sut = AuthServiceImpl(networkClient: mockClient)
        let result = try await sut.refreshToken("old-token")

        #expect(result.token == "refreshed")
    }

    @Test("refreshToken resets isLoading on failure")
    func refreshTokenFailure() async {
        let mockClient = MockNetworkClient()
        mockClient.sendHandler = { _ in throw NetworkError.unknown(NSError(domain: "test", code: 1)) }

        let sut = AuthServiceImpl(networkClient: mockClient)

        do {
            _ = try await sut.refreshToken("old")
            Issue.record("Expected error")
        } catch {
            #expect(sut.isLoading == false)
            #expect(sut.errorMessage != nil)
        }
    }

    // MARK: - Error message clearing

    @Test("successful request clears previous errorMessage")
    func clearsErrorMessage() async throws {
        let mockClient = MockNetworkClient()
        let sut = AuthServiceImpl(networkClient: mockClient)

        // First, trigger an error
        mockClient.sendHandler = { _ in throw NetworkError.invalidURL }
        _ = try? await sut.login(email: "a@b.com", password: "pass")
        #expect(sut.errorMessage != nil)

        // Then, successful request clears it
        mockClient.sendHandler = { _ in
            AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        }
        _ = try await sut.login(email: "a@b.com", password: "pass")
        #expect(sut.errorMessage == nil)
    }
}
