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
                // Для сообщений ассистента используем markdown, для пользователя - обычный текст
                if message.role == .assistant {
                    messageTextView
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
                        .overlay(alignment: .topTrailing) {
                            if let model = message.model, !model.isEmpty {
                                Text(model)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                                    .padding([.top, .trailing], 6)
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = message.text
                            }) {
                                Label("Копировать", systemImage: "doc.on.doc")
                            }
                        }
                } else {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.blue)
                        }
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = message.text
                            }) {
                                Label("Копировать", systemImage: "doc.on.doc")
                            }
                        }
                }
                
                Text(formatTime(message.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        date.formatted(date: .omitted, time: .shortened)
    }
    
    // MARK: - Markdown Support
    
    private var messageTextView: some View {
        Text(parseMarkdown(message.text))
            .font(.body)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
            let attributedString = try AttributedString(markdown: text, options: options)
            return attributedString
        } catch {
            return AttributedString(text)
        }
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
