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
            screenFactory.makeLoginView(path: $path)
                .navigationDestination(for: AuthCoordinator.self) { step in
                    switch step {
                    case .login:
                        screenFactory.makeLoginView(path: $path)
                    case .register:
                        screenFactory.makeRegisterView(path: $path)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
    }
}
