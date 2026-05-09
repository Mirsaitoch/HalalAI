//
//  ChatServiceImplTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct ChatServiceImplTests {

    // MARK: - clearChat

    @Test("clearChat removes all messages and resets state")
    func clearChat() {
        let (sut, _, _) = makeSUT()
        sut.messages = [
            ChatMessage(role: .user, text: "Hello"),
            ChatMessage(role: .assistant, text: "Hi")
        ]
        sut.chatState = .error("some error")

        sut.clearChat()

        #expect(sut.messages.isEmpty)
        #expect(sut.chatState == .idle)
    }

    // MARK: - sendMessage guards

    @Test("sendMessage ignores empty text")
    func sendMessageEmpty() {
        let (sut, _, _) = makeSUT()

        sut.sendMessage("")

        #expect(sut.messages.isEmpty)
        #expect(sut.chatState == .idle)
    }

    @Test("sendMessage ignores whitespace-only text")
    func sendMessageWhitespace() {
        let (sut, _, _) = makeSUT()

        sut.sendMessage("   \n  ")

        #expect(sut.messages.isEmpty)
    }

    @Test("sendMessage adds user message and sets typing state")
    func sendMessageAddsUserMessage() {
        let (sut, _, mockClient) = makeSUT()
        // Configure mock to handle the async request (will fail but that's ok for sync state check)
        mockClient.sendRawHandler = { _ in
            throw NSError(domain: "test", code: 1)
        }

        sut.sendMessage("Hello")

        #expect(sut.messages.count == 1)
        #expect(sut.messages[0].role == .user)
        #expect(sut.messages[0].text == "Hello")
        #expect(sut.chatState == .typing)
        #expect(sut.connectionState == .connecting)
    }

    // MARK: - retryLastMessage guards

    @Test("retryLastMessage does nothing without user messages")
    func retryNoMessages() {
        let (sut, _, _) = makeSUT()

        sut.retryLastMessage()

        #expect(sut.messages.isEmpty)
        #expect(sut.chatState == .idle)
    }

    // MARK: - Settings delegation

    @Test("userApiKey delegates to settingsStore")
    func userApiKeyDelegation() {
        let (sut, _, _) = makeSUT()

        sut.userApiKey = "test-key"
        #expect(sut.userApiKey == "test-key")
    }

    @Test("remoteModel delegates to settingsStore")
    func remoteModelDelegation() {
        let (sut, _, _) = makeSUT()

        sut.remoteModel = "gpt-4"
        #expect(sut.remoteModel == "gpt-4")
    }

    @Test("maxTokens delegates to settingsStore")
    func maxTokensDelegation() {
        let (sut, _, _) = makeSUT()

        sut.maxTokens = 4096
        #expect(sut.maxTokens == 4096)
    }

    @Test("temperature delegates to settingsStore")
    func temperatureDelegation() {
        let (sut, _, _) = makeSUT()

        sut.temperature = 1.2
        #expect(sut.temperature == 1.2)
    }

    @Test("useRag delegates to settingsStore")
    func useRagDelegation() {
        let (sut, _, _) = makeSUT()

        sut.useRag = false
        #expect(sut.useRag == false)
    }

    // MARK: - sendMessage with auth token

    @Test("sendMessage handles missing auth token")
    func sendMessageNoToken() async throws {
        let (sut, authManager, mockClient) = makeSUT()
        authManager.authToken = nil

        mockClient.sendRawHandler = { _ in
            throw NSError(domain: "test", code: 1)
        }

        sut.sendMessage("Hello")

        // Wait for async task
        try await Task.sleep(for: .milliseconds(100))

        // Should have user message + error message
        #expect(sut.messages.count == 2)
        #expect(sut.chatState != .typing)
    }

    @Test("sendMessage with valid token sends request")
    func sendMessageWithToken() async throws {
        let (sut, authManager, mockClient) = makeSUT()
        authManager.authToken = "valid-token"

        let responseJSON = """
        {"reply": "Hello from AI"}
        """.data(using: .utf8)!

        mockClient.sendRawHandler = { _ in
            let httpResponse = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (responseJSON, httpResponse)
        }

        sut.sendMessage("Hello")
        try await Task.sleep(for: .milliseconds(200))

        #expect(sut.messages.count == 2)
        #expect(sut.messages[1].role == .assistant)
        #expect(sut.messages[1].text == "Hello from AI")
        #expect(sut.chatState == .idle)
        #expect(sut.connectionState == .connected)
    }

    @Test("sendMessage handles server error")
    func sendMessageServerError() async throws {
        let (sut, authManager, mockClient) = makeSUT()
        authManager.authToken = "valid-token"

        mockClient.sendRawHandler = { _ in
            let httpResponse = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data("Internal Server Error".utf8), httpResponse)
        }

        sut.sendMessage("Hello")
        try await Task.sleep(for: .milliseconds(200))

        // User message + error message
        #expect(sut.messages.count == 2)
        #expect(sut.connectionState == .disconnected)
    }

    // MARK: - loadModels

    @Test("loadModels parses models response")
    func loadModelsSuccess() async {
        let (sut, _, mockClient) = makeSUT()

        let responseJSON = """
        {"default_model": "gpt-4", "allowed_models": ["gpt-4", "gpt-3.5"]}
        """.data(using: .utf8)!

        mockClient.sendRawHandler = { _ in
            let httpResponse = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (responseJSON, httpResponse)
        }

        await sut.loadModels()

        #expect(sut.availableModels == ["gpt-4", "gpt-3.5"])
        #expect(sut.defaultRemoteModel == "gpt-4")
    }

    @Test("loadModels handles error gracefully")
    func loadModelsError() async {
        let (sut, _, mockClient) = makeSUT()
        mockClient.sendRawHandler = { _ in throw NSError(domain: "test", code: 1) }

        await sut.loadModels()

        #expect(sut.availableModels.isEmpty)
    }

    @Test("loadModels sets remoteModel to default when current is empty")
    func loadModelsSetsDefault() async {
        let (sut, _, mockClient) = makeSUT()
        sut.remoteModel = ""

        let responseJSON = """
        {"default_model": "claude-3", "allowed_models": ["claude-3"]}
        """.data(using: .utf8)!

        mockClient.sendRawHandler = { _ in
            let httpResponse = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (responseJSON, httpResponse)
        }

        await sut.loadModels()

        #expect(sut.remoteModel == "claude-3")
    }

    // MARK: - Helpers

    private func makeSUT() -> (ChatServiceImpl, MockAuthManager, MockNetworkClient) {
        let authManager = MockAuthManager()
        let settingsStore = ChatSettingsStore()
        let mockClient = MockNetworkClient()
        let sut = ChatServiceImpl(
            authManager: authManager,
            settingsStore: settingsStore,
            networkClient: mockClient
        )
        return (sut, authManager, mockClient)
    }
}
