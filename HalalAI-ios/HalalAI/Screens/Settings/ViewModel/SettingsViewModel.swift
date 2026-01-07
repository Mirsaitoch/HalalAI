//
//  SettingsViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

extension SettingsView {
    @MainActor
    final class ViewModel: ObservableObject {
        var chatService: any ChatService
        var authManager: any AuthManager
        
        init(chatService: any ChatService, authManager: any AuthManager) {
            self.chatService = chatService
            self.authManager = authManager
        }

        @Published var isApiKeyVisible = false
        @Published var maxTokensSlider: Double = 2048
    }
}
