//
//  SettingsViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

extension SettingsView {
    @MainActor
    @Observable
    final class ViewModel {
        var chatService: ChatService
        var authManager: AuthManager
        
        init(chatService: ChatService, authManager: AuthManager) {
            self.chatService = chatService
            self.authManager = authManager
        }

        var isApiKeyVisible = false
        var maxTokensSlider: Double = 2048
    }
}
