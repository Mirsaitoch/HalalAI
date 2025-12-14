//
//  LoginView.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var authManager = AuthManager.shared
    
    @State private var usernameOrEmail: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var onShowRegister: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок
            VStack(spacing: 8) {
                Text("Добро пожаловать")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.greenForeground)
                
                Text("Войдите в свой аккаунт")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Форма входа
            VStack(spacing: 16) {
                // Поле имени пользователя или email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Имя пользователя или Email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Введите имя пользователя или email", text: $usernameOrEmail)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
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
                }
                
                // Кнопка входа
                Button(action: {
                    Task {
                        await login()
                    }
                }) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Войти")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.greenForeground)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(authService.isLoading || usernameOrEmail.isEmpty || password.isEmpty)
                .opacity((authService.isLoading || usernameOrEmail.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                
                // Кнопка регистрации
                HStack {
                    Text("Нет аккаунта?")
                        .foregroundColor(.secondary)
                    Button(action: {
                        onShowRegister()
                    }) {
                        Text("Зарегистрироваться")
                            .fontWeight(.semibold)
                            .foregroundColor(.greenForeground)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.greenBackground.ignoresSafeArea())
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func login() async {
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

#Preview {
    LoginView(onShowRegister: {})
}

