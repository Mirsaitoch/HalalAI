//
//  ChatModelsTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct ChatModelsTests {

    // MARK: - Role

    @Test("Role has user and assistant cases")
    func roleCases() {
        #expect(Role.allCases.count == 2)
        #expect(Role.user.rawValue == "user")
        #expect(Role.assistant.rawValue == "assistant")
    }

    @Test("Role encodes and decodes correctly",
          arguments: Role.allCases)
    func roleCodable(role: Role) throws {
        let data = try JSONEncoder().encode(role)
        let decoded = try JSONDecoder().decode(Role.self, from: data)
        #expect(decoded == role)
    }

    // MARK: - ChatMessage

    @Test("ChatMessage initializes with correct defaults")
    func chatMessageDefaults() {
        let message = ChatMessage(role: .user, text: "Салам")
        #expect(message.role == .user)
        #expect(message.text == "Салам")
        #expect(message.model == nil)
    }

    @Test("ChatMessage with model preserves model name")
    func chatMessageWithModel() {
        let message = ChatMessage(role: .assistant, text: "Ответ", model: "gpt-4")
        #expect(message.model == "gpt-4")
        #expect(message.role == .assistant)
    }

    @Test("ChatMessage encodes and decodes correctly")
    func chatMessageCodable() throws {
        let original = ChatMessage(role: .user, text: "Тест", model: "claude")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)

        #expect(decoded.role == .user)
        #expect(decoded.text == "Тест")
        #expect(decoded.model == "claude")
        #expect(decoded.id == original.id)
    }

    // MARK: - ChatState

    @Test("ChatState equality")
    func chatStateEquality() {
        #expect(ChatState.idle == ChatState.idle)
        #expect(ChatState.typing == ChatState.typing)
        #expect(ChatState.error("A") == ChatState.error("A"))
        #expect(ChatState.error("A") != ChatState.error("B"))
        #expect(ChatState.idle != ChatState.typing)
    }

    // MARK: - ConnectionState

    @Test("ConnectionState equality")
    func connectionStateEquality() {
        #expect(ConnectionState.connected == ConnectionState.connected)
        #expect(ConnectionState.disconnected != ConnectionState.connecting)
    }
}
