//
//  AuthCoordinator.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

enum AuthCoordinator: Hashable {
    case login
    case register
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .login:
            LoginView()
        case .register:
            RegisterView()
        }
    }
}
