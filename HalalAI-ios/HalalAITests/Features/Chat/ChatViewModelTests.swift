//
//  ChatViewModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct ChatViewModelTests {

    @Test("sendMessage trims whitespace and sends")
    func sendMessageTrimsAndSends() {
        let (vm, chatService) = makeSUT()
        vm.messageText = "  Привет  "

        vm.sendMessage()

        #expect(chatService.sendMessageCallCount == 1)
        #expect(chatService.lastSentMessage == "Привет")
        #expect(vm.messageText == "", "Input should be cleared after sending")
    }

    @Test("sendMessage ignores empty text")
    func sendMessageIgnoresEmpty() {
        let (vm, chatService) = makeSUT()
        vm.messageText = "   "

        vm.sendMessage()

        #expect(chatService.sendMessageCallCount == 0)
    }

    @Test("sendMessage ignores whitespace-only text")
    func sendMessageIgnoresWhitespace() {
        let (vm, chatService) = makeSUT()
        vm.messageText = "\n\t  "

        vm.sendMessage()

        #expect(chatService.sendMessageCallCount == 0)
    }

    @Test("sendMessage clears messageText after sending")
    func sendClearsInput() {
        let (vm, _) = makeSUT()
        vm.messageText = "Hello"

        vm.sendMessage()

        #expect(vm.messageText.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (ChatView.ViewModel, MockChatService) {
        let chatService = MockChatService()
        let authManager = MockAuthManager()
        let vm = ChatView.ViewModel(chatService: chatService, authManager: authManager)
        return (vm, chatService)
    }
}
