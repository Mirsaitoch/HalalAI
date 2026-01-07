//
//  ScreenFactory.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 07.01.2026.
//

import Foundation
import SwiftUI

protocol ScreenFactory {}

@MainActor
let screenFactory = ScreenFactoryImpl()

@MainActor
final class ScreenFactoryImpl {
    fileprivate init() {}
    fileprivate let dc = DependencyContainer()
    
    func makeLoginView(path: Binding<[AuthCoordinator]>) -> LoginView {
        let viewModel = LoginView.ViewModel(authManager: dc.authManager, authService: dc.authService)
        return LoginView(viewModel: viewModel) {
            path.wrappedValue = [.register]
        }
    }
    
    func makeRegisterView(path: Binding<[AuthCoordinator]>) -> RegisterView {
        let viewModel = RegisterView.ViewModel(authManager: dc.authManager, authService: dc.authService)
        return RegisterView(viewModel: viewModel) {
            path.wrappedValue = []
        }
    }
    
    func makeRootView() -> RootView {
        RootView(authManager: dc.authManager)
    }
    
    func makeSettingsView() -> SettingsView {
        let viewModel = SettingsView.ViewModel(chatService: dc.chatService, authManager: dc.authManager)
        return SettingsView(viewModel: viewModel)
    }
    
    func makeChatView() -> ChatView {
        let viewModel = ChatView.ViewModel(chatService: dc.chatService)
        return ChatView(viewModel: viewModel)
    }
}

@MainActor
final class DependencyContainer {
    fileprivate var authManager: any AuthManager
    fileprivate var authService: any AuthService
    fileprivate var chatService: any ChatService

    init() {
        self.authManager = AuthManagerImpl()
        self.authService = AuthServiceImpl()
        self.chatService = ChatServiceImpl(authManager: authManager)
    }
}
