//
//  RegisterView.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var authManager = AuthManager.shared
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var onShowLogin: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Заголовок
                VStack(spacing: 8) {
                    Text("Регистрация")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.greenForeground)
                    
                    Text("Создайте новый аккаунт")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Форма регистрации
                VStack(spacing: 16) {
                    // Поле имени пользователя
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Имя пользователя")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Введите имя пользователя", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                    
                    // Поле email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Введите email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    
                    // Поле пароля
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пароль")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showPassword {
                                TextField("Введите пароль", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Введите пароль", text: $password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        if !password.isEmpty && password.count < 8 {
                            Text("Пароль должен содержать минимум 8 символов")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Поле подтверждения пароля
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Подтвердите пароль")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("Повторите пароль", text: $confirmPassword)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Повторите пароль", text: $confirmPassword)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Пароли не совпадают")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Кнопка регистрации
                    Button(action: {
                        Task {
                            await register()
                        }
                    }) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Зарегистрироваться")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.greenForeground : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || authService.isLoading)
                    .opacity((!isFormValid || authService.isLoading) ? 0.6 : 1.0)
                    
                    // Кнопка входа
                    HStack {
                        Text("Уже есть аккаунт?")
                            .foregroundColor(.secondary)
                        Button(action: {
                            onShowLogin()
                        }) {
                            Text("Войти")
                                .fontWeight(.semibold)
                                .foregroundColor(.greenForeground)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.greenBackground.ignoresSafeArea())
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Private Methods
    
    private func register() async {
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

#Preview {
    RegisterView(onShowLogin: {})
}

