//
//  RegisterView.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

struct RegisterView: View {
    @Bindable var viewModel: ViewModel
    var onShowLogin: (() -> Void)? = nil

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
                        
                        TextField("Введите имя пользователя", text: $viewModel.username)
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
                        
                        TextField("Введите email", text: $viewModel.email)
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
                        
                        if !viewModel.password.isEmpty && viewModel.password.count < 8 {
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
                            if viewModel.showConfirmPassword {
                                TextField("Повторите пароль", text: $viewModel.confirmPassword)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Повторите пароль", text: $viewModel.confirmPassword)
                            }
                            
                            Button(action: { viewModel.showConfirmPassword.toggle() }) {
                                Image(systemName: viewModel.showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                            Text("Пароли не совпадают")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Кнопка регистрации
                    Button(action: {
                        Task {
                            await viewModel.register()
                        }
                    }) {
                        HStack {
                            if viewModel.authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Зарегистрироваться")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.isFormValid ? Color.greenForeground : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.authService.isLoading)
                    .opacity((!viewModel.isFormValid || viewModel.authService.isLoading) ? 0.6 : 1.0)
                    
                    // Кнопка входа
                    HStack {
                        Text("Уже есть аккаунт?")
                            .foregroundColor(.secondary)
                        Button(action: {
                            onShowLogin?()
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
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }   
}
