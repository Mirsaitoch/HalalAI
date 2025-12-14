//
//  AuthCoordinator.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

enum AuthCoordinator {
    case login
    case register
    
    var view: some View {
        switch self {
        case .login:
            AuthView(initialView: .login)
        case .register:
            AuthView(initialView: .register)
        }
    }
}

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var currentView: AuthViewType = .login
    
    enum AuthViewType {
        case login
        case register
    }
    
    let initialView: AuthViewType
    
    init(initialView: AuthViewType = .login) {
        self.initialView = initialView
        _currentView = State(initialValue: initialView)
    }
    
    var body: some View {
        Group {
            switch currentView {
            case .login:
                LoginView(onShowRegister: {
                    withAnimation {
                        currentView = .register
                    }
                })
            case .register:
                RegisterView(onShowLogin: {
                    withAnimation {
                        currentView = .login
                    }
                })
            }
        }
    }
}

