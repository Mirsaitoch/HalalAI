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
    final class ViewModel {
        var authManager: AuthManager
        var authService: AuthService
        
        init(authManager: AuthManager, authService: AuthService) {
            self.authManager = authManager
            self.authService = authService
        }
        
        var email: String = ""
        var password: String = ""
        var showPassword: Bool = false
        var showError: Bool = false
        var errorMessage: String = ""
        var isDisable: Bool {
            authService.isLoading || email.isEmpty || password.isEmpty
        }
        
        func login() async {
            guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !password.isEmpty else {
                errorMessage = "Заполните все поля"
                showError = true
                return
            }
            
            do {
                let response = try await authService.login(
                    email: email,
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
