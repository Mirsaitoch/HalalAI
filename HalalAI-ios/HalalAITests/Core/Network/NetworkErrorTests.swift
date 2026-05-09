//
//  NetworkErrorTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct NetworkErrorTests {

    @Test("NetworkError cases are distinct",
          arguments: [
            ("invalidURL", NetworkError.invalidURL),
            ("invalidResponse", NetworkError.invalidResponse),
            ("serverError", NetworkError.serverError(statusCode: 500, data: Data())),
            ("decodingError", NetworkError.decodingError(NSError(domain: "test", code: 1))),
            ("unknown", NetworkError.unknown(NSError(domain: "test", code: 2)))
          ])
    func distinctCases(label: String, error: NetworkError) {
        switch error {
        case .invalidURL:
            #expect(label == "invalidURL")
        case .invalidResponse:
            #expect(label == "invalidResponse")
        case .serverError:
            #expect(label == "serverError")
        case .decodingError:
            #expect(label == "decodingError")
        case .unknown:
            #expect(label == "unknown")
        }
    }

    @Test("serverError preserves statusCode and data")
    func serverErrorPreservesData() {
        let data = Data("error body".utf8)
        let error = NetworkError.serverError(statusCode: 422, data: data)

        if case .serverError(let code, let body) = error {
            #expect(code == 422)
            #expect(String(data: body, encoding: .utf8) == "error body")
        } else {
            Issue.record("Expected serverError")
        }
    }

    @Test("decodingError preserves underlying error")
    func decodingErrorPreservesUnderlying() {
        let underlying = NSError(domain: "DecoderError", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "Type mismatch"
        ])
        let error = NetworkError.decodingError(underlying)

        if case .decodingError(let inner) = error {
            #expect((inner as NSError).code == 42)
        } else {
            Issue.record("Expected decodingError")
        }
    }

    @Test("unknown preserves underlying error")
    func unknownPreservesUnderlying() {
        let underlying = NSError(domain: "NSURLErrorDomain", code: -1009)
        let error = NetworkError.unknown(underlying)

        if case .unknown(let inner) = error {
            #expect((inner as NSError).domain == "NSURLErrorDomain")
        } else {
            Issue.record("Expected unknown")
        }
    }
}
