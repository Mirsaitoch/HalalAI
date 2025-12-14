//
//  EmptyChatView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import SwiftUI

struct EmptyChatView: View {
    @State private var isAnimating = false
    @StateObject private var chatService = ChatService.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 16) {
                Text("Ассаламу алейкум 👋")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Я — HalalAI, ваш халяль-помощник.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Спросите меня о продуктах, брендах или правилах халяль.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Spacer()
                        QuickQuestionButton(text: "Что такое халяль?", onTap: { chatService.sendMessage("Что такое халяль?") })
                        QuickQuestionButton(text: "Халяль мясо", onTap: { chatService.sendMessage("Расскажи о халяль мясе") })
                        QuickQuestionButton(text: "Молочные продукты", onTap: { chatService.sendMessage("Какие молочные продукты халяль?") })
                        QuickQuestionButton(text: "Популярные бренды", onTap: { chatService.sendMessage("Какие популярные халяль бренды?") })
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct QuickQuestionButton: View {
    let text: String
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            Text(text)
                .font(.caption)
                .foregroundColor(.darkGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.greenForeground)
                }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) {
            // Действие при долгом нажатии
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

#Preview {
    EmptyChatView()
        .background(Color(.systemGroupedBackground))
}
