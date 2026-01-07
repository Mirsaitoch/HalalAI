//
//  RegisterViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

extension RegisterView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var username: String = ""
        @Published var email: String = ""
        @Published var password: String = ""
        @Published var confirmPassword: String = ""
        @Published var showPassword: Bool = false
        @Published var showConfirmPassword: Bool = false
        @Published var showError: Bool = false
        @Published var errorMessage: String = ""
        
        var authManager: any AuthManager
        var authService: any AuthService
        
        init(authManager: any AuthManager, authService: any AuthService, ) {
            self.authManager = authManager
            self.authService = authService
        }
        
        var isFormValid: Bool {
            !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            password.count >= 8 &&
            password == confirmPassword &&
            isValidEmail(email)
        }
        
        func isValidEmail(_ email: String) -> Bool {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: email)
        }
        
        func register() async {
            guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  password.count >= 8,
                  password == confirmPassword else {
                errorMessage = "Проверьте правильность заполнения всех полей"
                showError = true
                return
            }
            
            guard isValidEmail(email) else {
                errorMessage = "Введите корректный email адрес"
                showError = true
                return
            }
            
            do {
                let response = try await authService.register(
                    username: username,
                    email: email,
                    password: password
                )
                authManager.saveAuth(response)
            } catch let error as AuthError {
                errorMessage = error.errorDescription ?? "Неизвестная ошибка"
                showError = true
            } catch {
                errorMessage = "Произошла ошибка при регистрации"
                showError = true
            }
        }
    }
}
