//
//  ChatUtils.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import Foundation
import SwiftUI

// MARK: - Chat Utilities

struct ChatUtils {
    
    // MARK: - Text Processing
    
    static func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func formatMessageDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    static func isYesterday(_ date: Date) -> Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    // MARK: - Message Validation
    
    static func isValidMessage(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 2000
    }
    
    static func sanitizeMessage(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - UI Helpers
    
    static func getMessageBubbleColor(for role: Role) -> Color {
        switch role {
        case .user:
            return .blue
        case .assistant:
            return .green.opacity(0.1)
        }
    }
    
    static func getMessageTextColor(for role: Role) -> Color {
        switch role {
        case .user:
            return .white
        case .assistant:
            return .primary
        }
    }
}

// MARK: - Chat Constants

struct ChatConstants {
    static let maxMessageLength = 2000
    static let maxMessagesInHistory = 100
    static let typingIndicatorDelay: TimeInterval = 0.5
    static let messageAnimationDuration: TimeInterval = 0.3
    static let scrollAnimationDuration: TimeInterval = 0.3
}

// MARK: - Chat Colors

struct ChatColors {
    static let userBubble = Color.blue
    static let assistantBubble = Color.green.opacity(0.1)
    static let assistantBubbleBorder = Color.green.opacity(0.3)
    static let errorBubble = Color.red.opacity(0.1)
    static let errorBubbleBorder = Color.red.opacity(0.3)
    static let inputBackground = Color(.systemGray6)
    static let sendButton = Color.blue
    static let microphoneButton = Color.blue
    static let quickQuestionButton = Color.blue.opacity(0.1)
    static let quickQuestionBorder = Color.blue.opacity(0.3)
}
