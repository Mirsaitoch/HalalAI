//
//  RouterView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.10.2025.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                RouterView {
                    HomeView()
                }
            } else {
                AuthView(initialView: .login)
            }
        }
    }
}
