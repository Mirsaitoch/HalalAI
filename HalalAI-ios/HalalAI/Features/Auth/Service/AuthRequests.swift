//
//  AuthRequests.swift
//  HalalAI
//
//  Типизированные API-запросы для аутентификации.
//

import Foundation

struct LoginAPIRequest: APIRequest {
    typealias Response = AuthResponse

    let endpoint = Endpoint.login
    let body: (any Encodable & Sendable)?

    init(body: LoginRequest) {
        self.body = body
    }
}

struct RegisterAPIRequest: APIRequest {
    typealias Response = AuthResponse

    let endpoint = Endpoint.register
    let body: (any Encodable & Sendable)?
    let expectedStatus = 201

    init(body: RegisterRequest) {
        self.body = body
    }
}

struct RefreshTokenAPIRequest: APIRequest {
    typealias Response = AuthResponse

    let endpoint = Endpoint.refreshToken
    let body: (any Encodable & Sendable)?

    init(body: RefreshTokenRequest) {
        self.body = body
    }
}
