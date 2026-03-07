//
//  LoginView.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: ViewModel
    var onShowRegister: (() -> Void)? = nil

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

                    Text("Войдите в свой аккаунт")
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
                                    placeholder: "Имя пользователя или Email",
                                    text: $viewModel.usernameOrEmail
                                )

                                AuthTextField(
                                    icon: "lock.fill",
                                    placeholder: "Пароль",
                                    text: $viewModel.password,
                                    isSecure: true
                                )
                            }

                            // Login button
                            Button(action: {
                                Task { await viewModel.login() }
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
                                .frame(height: 52)
                                .background(viewModel.isDisable ? Color.gray : Color.greenForeground)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(viewModel.isDisable)
                            .opacity(viewModel.isDisable ? 0.6 : 1.0)

                            // Register link
                            HStack(spacing: 4) {
                                Text("Нет аккаунта?")
                                    .foregroundColor(.secondary)
                                Button(action: { onShowRegister?() }) {
                                    Text("Зарегистрироваться")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.greenForeground)
                                }
                            }

                            // Guest login
                            Button(action: {
                                viewModel.authManager.continueAsGuest()
                            }) {
                                Text("Продолжить без регистрации")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
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
