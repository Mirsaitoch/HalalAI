//
//  LoginViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

extension LoginView {
    @MainActor
    @Observable
    final class ViewModel: ObservableObject {
        var authManager: any AuthManager
        var authService: any AuthService
        
        init(authManager: any AuthManager, authService: any AuthService) {
            self.authManager = authManager
            self.authService = authService
        }
        
        var usernameOrEmail: String = ""
        var password: String = ""
        var showPassword: Bool = false
        var showError: Bool = false
        var errorMessage: String = ""
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
