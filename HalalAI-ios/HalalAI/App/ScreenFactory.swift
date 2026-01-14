//
//  ScreenFactory.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 07.01.2026.
//

import Foundation
import SwiftUI

protocol ScreenFactory {
    func makeLoginView(path: Binding<[AuthCoordinator]>) -> LoginView
    func makeRegisterView(path: Binding<[AuthCoordinator]>) -> RegisterView
    func makeRootView() -> RootView
    func makeSettingsView() -> SettingsView
    func makeChatView() -> ChatView
    func makeScannerView() -> ScannerView
    func makeHomeView() -> HomeView
}

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
    
    func makeScannerView() -> ScannerView {
        let viewModel = ScannerView.ViewModel(ingredientService: dc.ingredientService)
        return ScannerView(viewModel: viewModel)
    }
    
    func makeHomeView() -> HomeView {
        return HomeView(verseService: dc.verseService)
    }
}

@MainActor
final class DependencyContainer {
    fileprivate var authManager: AuthManager
    fileprivate var authService: AuthService
    fileprivate var chatService: ChatService
    fileprivate var ingredientService: IngredientService
    fileprivate var verseService: VerseService
    
    init() {
        self.authManager = AuthManagerImpl()
        self.authService = AuthServiceImpl()
        self.chatService = ChatServiceImpl(authManager: authManager)
        self.ingredientService = IngredientServiceImpl()
        self.verseService = VerseServiceImpl()
    }
}
