//
//  DependencyContainer.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

@MainActor
protocol DependencyContainerProtocol: ObservableObject {
    var chatService: ChatServiceImpl { get }
    var authService: AuthServiceImpl { get }
    var authManager: AuthManagerImpl { get }
}

@MainActor
class DependencyContainer: DependencyContainerProtocol {
    static let shared = DependencyContainer()
    private init() {}
    
    private(set) lazy var authManager: AuthManagerImpl = {
        AuthManagerImpl()
    }()
    private(set) lazy var authService: AuthServiceImpl = {
        AuthServiceImpl()
    }()
    private(set) lazy var chatService: ChatServiceImpl = {
        _ = self.authManager
        return ChatServiceImpl(authManager: authManager)
    }()
}
