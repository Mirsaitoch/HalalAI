//
//  ChatViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 07.01.2026.
//

import SwiftUI

extension ChatView {
    @Observable
    final class ViewModel {
        var messageText = ""
        let chatService: ChatService
        
        init(chatService: ChatService) {
            self.chatService = chatService
        }
        
        @MainActor
        func sendMessage() {
            let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else { return }
            
            chatService.sendMessage(trimmedText)
            messageText = ""
        }
    }
}
