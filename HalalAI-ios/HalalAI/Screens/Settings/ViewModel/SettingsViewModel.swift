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
        var chatService = DependencyContainer.shared.chatService
        var authManager = DependencyContainer.shared.authManager

        @Published var isApiKeyVisible = false
        @Published var maxTokensSlider: Double = 2048
    }
}
