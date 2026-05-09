//
//  SettingsViewModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct SettingsViewModelTests {

    @Test("Initial state has correct defaults")
    func initialState() {
        let (vm, _, _) = makeSUT()

        #expect(vm.isApiKeyVisible == false)
        #expect(vm.maxTokensSlider == 2048)
        #expect(vm.temperatureSlider == 0.7)
        #expect(vm.useCustomModel == false)
    }

    @Test("chatService properties are accessible")
    func chatServiceAccess() {
        let (vm, chatService, _) = makeSUT()
        chatService.userApiKey = "test-key"
        chatService.remoteModel = "gpt-4"

        #expect(vm.chatService.userApiKey == "test-key")
        #expect(vm.chatService.remoteModel == "gpt-4")
    }

    @Test("authManager state is accessible")
    func authManagerAccess() {
        let (vm, _, authManager) = makeSUT()

        #expect(vm.authManager.isAuthenticated == false)

        authManager.saveAuth(AuthResponse(token: "t", type: "Bearer", userId: 1, email: "e@e.com"))

        #expect(vm.authManager.isAuthenticated == true)
    }

    @Test("isApiKeyVisible can be toggled")
    func toggleApiKeyVisibility() {
        let (vm, _, _) = makeSUT()

        vm.isApiKeyVisible = true
        #expect(vm.isApiKeyVisible == true)

        vm.isApiKeyVisible = false
        #expect(vm.isApiKeyVisible == false)
    }

    @Test("useCustomModel can be toggled")
    func toggleCustomModel() {
        let (vm, _, _) = makeSUT()

        vm.useCustomModel = true
        #expect(vm.useCustomModel == true)
    }

    @Test("slider values can be changed")
    func sliderValues() {
        let (vm, _, _) = makeSUT()

        vm.maxTokensSlider = 4096
        vm.temperatureSlider = 1.5

        #expect(vm.maxTokensSlider == 4096)
        #expect(vm.temperatureSlider == 1.5)
    }

    // MARK: - Helpers

    private func makeSUT() -> (SettingsView.ViewModel, MockChatService, MockAuthManager) {
        let chatService = MockChatService()
        let authManager = MockAuthManager()
        let vm = SettingsView.ViewModel(chatService: chatService, authManager: authManager)
        return (vm, chatService, authManager)
    }
}
