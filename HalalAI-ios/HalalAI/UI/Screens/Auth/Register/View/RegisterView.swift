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
        ZStack(alignment: .bottom) {
            Color.greenForeground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)

                    Text("Halal AI")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)

                    Text("Создайте новый аккаунт")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 70)
                .padding(.bottom, 40)

                // White card
                ZStack(alignment: .top) {
                    // Background extends to bottom edge
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 32
                    )
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea(edges: .bottom)

                    // ScrollView moves with keyboard
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 14) {
                                AuthTextField(
                                    icon: "person.fill",
                                    placeholder: "Имя пользователя",
                                    text: $viewModel.username
                                )

                                AuthTextField(
                                    icon: "envelope.fill",
                                    placeholder: "Email",
                                    text: $viewModel.email
                                )

                                VStack(alignment: .leading, spacing: 6) {
                                    AuthTextField(
                                        icon: "lock.fill",
                                        placeholder: "Пароль",
                                        text: $viewModel.password,
                                        isSecure: true
                                    )
                                    if !viewModel.password.isEmpty && viewModel.password.count < 8 {
                                        Text("Пароль должен содержать минимум 8 символов")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 4)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    AuthTextField(
                                        icon: "lock.fill",
                                        placeholder: "Подтвердите пароль",
                                        text: $viewModel.confirmPassword,
                                        isSecure: true
                                    )
                                    if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                                        Text("Пароли не совпадают")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 4)
                                    }
                                }
                            }

                            // Register button
                            Button(action: {
                                Task { await viewModel.register() }
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
                                .frame(height: 52)
                                .background(viewModel.isFormValid ? Color.greenForeground : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(!viewModel.isFormValid || viewModel.authService.isLoading)
                            .opacity((!viewModel.isFormValid || viewModel.authService.isLoading) ? 0.6 : 1.0)

                            // Login link
                            HStack(spacing: 4) {
                                Text("Уже есть аккаунт?")
                                    .foregroundColor(.secondary)
                                Button(action: { onShowLogin?() }) {
                                    Text("Войти")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.greenForeground)
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 36)
                        .padding(.bottom, 40)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
