//
//  AuthRequestsTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct AuthRequestsTests {

    @Test("LoginAPIRequest has correct endpoint and default status")
    func loginRequest() {
        let body = LoginRequest(email: "test@test.com", password: "pass")
        let request = LoginAPIRequest(body: body)
        #expect(request.endpoint.path == "/api/auth/login")
        #expect(request.endpoint.method == .post)
        #expect(request.expectedStatus == 200)
        #expect(request.token == nil)
        #expect(request.timeout == 30)
    }

    @Test("RegisterAPIRequest expects 201 status")
    func registerRequest() {
        let body = RegisterRequest(email: "test@test.com", password: "pass")
        let request = RegisterAPIRequest(body: body)
        #expect(request.endpoint.path == "/api/auth/register")
        #expect(request.expectedStatus == 201)
    }

    @Test("RefreshTokenAPIRequest has correct endpoint")
    func refreshTokenRequest() {
        let body = RefreshTokenRequest(token: "old-token")
        let request = RefreshTokenAPIRequest(body: body)
        #expect(request.endpoint.path == "/api/auth/refresh")
        #expect(request.expectedStatus == 200)
    }
}
