//
//  ChatModels.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import Foundation

// MARK: - Chat Models

enum Role: String, CaseIterable, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    let text: String
    let date: Date
    
    init(role: Role, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.date = Date()
    }
}

// MARK: - Chat States

enum ChatState: Equatable {
    case idle
    case typing
    case error(String)
}

// MARK: - Connection State

enum ConnectionState: Equatable {
    case connected
    case disconnected
    case connecting
}
