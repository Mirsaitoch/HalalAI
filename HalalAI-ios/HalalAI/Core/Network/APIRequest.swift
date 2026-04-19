//
//  APIRequest.swift
//  HalalAI
//
//  Протокол типизированного API-запроса с ассоциированным типом ответа.
//

import Foundation

protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    var endpoint: Endpoint { get }
    var body: (any Encodable & Sendable)? { get }
    var token: String? { get }
    var timeout: TimeInterval { get }
    var expectedStatus: Int { get }
}

// MARK: - Дефолтные значения

extension APIRequest {
    var body: (any Encodable & Sendable)? { nil }
    var token: String? { nil }
    var timeout: TimeInterval { 30 }
    var expectedStatus: Int { 200 }
}
