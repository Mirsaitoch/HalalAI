//
//  MessageBubble.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.role == .user ? Color.blue : Color.green.opacity(0.1))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(message.role == .user ? Color.clear : Color.green.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = message.text
                        }) {
                            Label("Копировать", systemImage: "doc.on.doc")
                        }
                    }
                
                Text(formatTime(message.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1) {
            // Дополнительные действия при долгом нажатии
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.green.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    }
            }
            
            Spacer()
        }
        .onAppear {
            animationOffset = -4
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(message: ChatMessage(role: .user, text: "Привет! Расскажи о халяль продуктах"))
        MessageBubble(message: ChatMessage(role: .assistant, text: "Ассаламу алейкум! 👋\n\nЯ — HalalAI, ваш халяль-помощник. Готов ответить на ваши вопросы о халяль продуктах, брендах и исламских принципах питания."))
        TypingIndicator()
    }
    .padding()
}
