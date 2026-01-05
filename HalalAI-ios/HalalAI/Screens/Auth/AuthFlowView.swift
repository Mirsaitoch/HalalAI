//
//  AuthFlowView.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

struct AuthFlowView: View {
    @State private var path: [AuthCoordinator] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            LoginView(onShowRegister: { path = [.register] })
                .navigationDestination(for: AuthCoordinator.self) { step in
                    switch step {
                    case .login:
                        LoginView(onShowRegister: { path = [.register] })
                    case .register:
                        RegisterView(onShowLogin: { path = [] })
                            .navigationBarBackButtonHidden()
                    }
                }
        }
    }
}
