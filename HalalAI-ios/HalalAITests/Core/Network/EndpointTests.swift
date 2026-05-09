//
//  EndpointTests.swift
//  HalalAITests
//

import Testing
@testable import HalalAI

struct EndpointTests {

    @Test("Auth endpoints have correct paths",
          arguments: [
            (Endpoint.login, "/api/auth/login"),
            (Endpoint.register, "/api/auth/register"),
            (Endpoint.refreshToken, "/api/auth/refresh")
          ])
    func authPaths(endpoint: Endpoint, expectedPath: String) {
        #expect(endpoint.path == expectedPath)
    }

    @Test("Chat endpoint path")
    func chatPath() {
        #expect(Endpoint.chat.path == "/api/chat")
    }

    @Test("Models endpoint path")
    func modelsPath() {
        #expect(Endpoint.models.path == "/api/models")
    }

    @Test("Verse of the day endpoint path")
    func versePath() {
        #expect(Endpoint.verseOfTheDay.path == "/api/verse-of-the-day")
    }

    @Test("Auth endpoints use POST",
          arguments: [Endpoint.login, .register, .refreshToken, .chat])
    func postEndpoints(endpoint: Endpoint) {
        #expect(endpoint.method == .post)
    }

    @Test("Read-only endpoints use GET",
          arguments: [Endpoint.models, .verseOfTheDay])
    func getEndpoints(endpoint: Endpoint) {
        #expect(endpoint.method == .get)
    }
}
