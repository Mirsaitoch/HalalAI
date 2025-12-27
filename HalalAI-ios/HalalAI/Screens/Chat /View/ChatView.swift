//
//  ChatView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService.shared
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    if chatService.messages.isEmpty {
                        EmptyChatView()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(chatService.messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                            .transition(.asymmetric(
                                                insertion: .scale.combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                    }
                                    
                                    // Индикатор печати
                                    if chatService.chatState == .typing {
                                        TypingIndicator()
                                            .id("typing")
                                    }
                                    
                                    // Сообщение об ошибке
                                    if case .error(let errorMessage) = chatService.chatState {
                                        ErrorMessageView(
                                            message: errorMessage,
                                            onRetry: {
                                                chatService.retryLastMessage()
                                            }
                                        )
                                        .id("error")
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                InputBar(
                    messageText: $messageText,
                    onSend: sendMessage,
                    onMicrophoneTap: {
                        // TODO: Реализовать голосовой ввод, пока кнопка скрыта
                        print("Микрофон нажат")
                    }
                )
            }
            .navigationTitle("Halal AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // TODO: Открыть настройки модели
                        }) {
                            Label("Настройки модели", systemImage: "gearshape")
                        }
                                                
                        Button(action: {
                            chatService.clearChat()
                        }) {
                            Label("Очистить чат", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .background {
                Color.greenBackground.ignoresSafeArea()
            }
        }
//        .onTapGesture {
//            hideKeyboard()
//        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        chatService.sendMessage(trimmedText)
        messageText = ""
    }
}

struct ErrorMessageView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Ошибка соединения")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button(action: onRetry) {
                    Text("Повторить отправку")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    }
            }
            
            Spacer()
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
    }
}

#Preview {
    ChatView()
}
