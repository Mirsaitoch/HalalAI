//
//  LoginView.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

struct LoginView: View {
    var onShowRegister: (() -> Void)? = nil
    
    @StateObject var viewModel = ViewModel()

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
                    
                    TextField("Введите имя пользователя или email", text: $viewModel.usernameOrEmail)
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
                        if viewModel.showPassword {
                            TextField("Введите пароль", text: $viewModel.password)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Введите пароль", text: $viewModel.password)
                        }
                        
                        Button(action: { viewModel.showPassword.toggle() }) {
                            Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
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
                        await viewModel.login()
                    }
                }) {
                    HStack {
                        if viewModel.authService.isLoading {
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
                .disabled(viewModel.isDisable)
                .opacity((viewModel.isDisable) ? 0.6 : 1.0)
                
                // Кнопка регистрации
                HStack {
                    Text("Нет аккаунта?")
                        .foregroundColor(.secondary)
                    Button(action: {
                        onShowRegister?()
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
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
