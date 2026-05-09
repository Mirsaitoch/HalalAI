//
//  NetworkClient.swift
//  HalalAI
//
//  Sendable обёртка над URLSession. Принимает типизированные APIRequest.
//

import Foundation

protocol NetworkClientProtocol: Sendable {
    func send<R: APIRequest>(_ request: R) async throws -> R.Response
    func sendRaw<R: APIRequest>(_ request: R) async throws -> (Data, HTTPURLResponse)
}

struct NetworkClient: NetworkClientProtocol, Sendable {

    private let session: URLSession = .shared
    private var baseURL: String { APIConfiguration.backendURL }

    // MARK: - Типизированный запрос

    /// Выполняет APIRequest и декодирует ответ в `R.Response`.
    func send<R: APIRequest>(_ request: R) async throws(NetworkError) -> R.Response {
        let (data, response) = try await sendRaw(request)

        guard response.statusCode == request.expectedStatus else {
            throw .serverError(statusCode: response.statusCode, data: data)
        }

        do {
            return try JSONDecoder().decode(R.Response.self, from: data)
        } catch {
            throw .decodingError(error)
        }
    }

    // MARK: - Сырой запрос

    /// Выполняет APIRequest и возвращает сырые данные + HTTPURLResponse.
    /// Используется, когда нужен ручной разбор ответа (например ChatService).
    func sendRaw<R: APIRequest>(_ request: R) async throws(NetworkError) -> (Data, HTTPURLResponse) {
        guard let url = URL(string: "\(baseURL)\(request.endpoint.path)") else {
            throw .invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.endpoint.method.rawValue
        urlRequest.timeoutInterval = request.timeout
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

        if let token = request.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = request.body {
            do {
                urlRequest.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw .unknown(error)
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw .unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }

        return (data, httpResponse)
    }
}

// MARK: - HTTPMethod

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
