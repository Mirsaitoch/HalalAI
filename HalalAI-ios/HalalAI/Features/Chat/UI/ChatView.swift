//
//  ChatView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct ChatView: View {
    @State private var viewModel: ViewModel
    @Environment(Coordinator.self) var coordinator

    init(chatService: ChatService, authManager: AuthManager) {
        _viewModel = State(initialValue: ViewModel(chatService: chatService, authManager: authManager))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        VStack(spacing: 0) {
            ZStack {
                if vm.chatService.messages.isEmpty {
                    EmptyChatView(chatService: vm.chatService)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(vm.chatService.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                                
                                // Индикатор печати
                                if vm.chatService.chatState == .typing {
                                    TypingIndicator()
                                        .id("typing")
                                }
                                
                                // Сообщение об ошибке
                                if case .error(let errorMessage) = vm.chatService.chatState {
                                    ErrorMessageView(
                                        message: errorMessage,
                                        onRetry: {
                                            vm.chatService.retryLastMessage()
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
                messageText: $vm.messageText,
                onSend: vm.sendMessage,
                onMicrophoneTap: {
                    // TODO: Реализовать голосовой ввод, пока кнопка скрыта
                    print("Микрофон нажат")
                }
            )
        }
        .navigationTitle("Halal AI")
        .toolbar(vm.authManager.isGuest ? .hidden : .visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !vm.authManager.isGuest {
                    Menu {
                        Button(action: {
                            coordinator.currentSelectedTab = .settings
                        }) {
                            Label("Настройки модели", systemImage: "gearshape")
                        }
                        
                        Button(action: {
                            vm.chatService.clearChat()
                        }) {
                            Label("Очистить чат", systemImage: "trash")
                        }
                    } label: {
                        Label("Опции", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .background {
            Color.greenBackground.ignoresSafeArea()
        }
        .overlay {
            if vm.authManager.isGuest {
                GuestAuthPromptView(featureName: "ИИ-чат", authManager: vm.authManager)
            }
        }
    }
}


