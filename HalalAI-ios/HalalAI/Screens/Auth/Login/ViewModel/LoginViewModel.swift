//
//  LoginViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

extension LoginView {
    @MainActor
    final class ViewModel: ObservableObject {
        var authManager: AuthManagerImpl
        var authService: AuthServiceImpl
        
        init() {
            let dc = DependencyContainer.shared
            self.authManager = dc.authManager
            self.authService = dc.authService
        }
        
        @Published var usernameOrEmail: String = ""
        @Published var password: String = ""
        @Published var showPassword: Bool = false
        @Published var showError: Bool = false
        @Published var errorMessage: String = ""
        var isDisable: Bool {
            authService.isLoading || usernameOrEmail.isEmpty || password.isEmpty
        }
        
        func login() async {
            guard !usernameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !password.isEmpty else {
                errorMessage = "Заполните все поля"
                showError = true
                return
            }
            
            do {
                let response = try await authService.login(
                    usernameOrEmail: usernameOrEmail,
                    password: password
                )
                authManager.saveAuth(response)
            } catch let error as AuthError {
                errorMessage = error.errorDescription ?? "Неизвестная ошибка"
                showError = true
            } catch {
                errorMessage = "Произошла ошибка при входе"
                showError = true
            }
        }
    }
}
