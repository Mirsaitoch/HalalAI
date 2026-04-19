//
//  RegisterView.swift
//  HalalAI
//
//  Created by Auto on 2025.
//

import SwiftUI

struct RegisterView: View {
    @State private var viewModel: ViewModel
    private let onShowLogin: (() -> Void)?

    init(
        authManager: AuthManager,
        authService: AuthService,
        onShowLogin: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: ViewModel(authManager: authManager, authService: authService))
        self.onShowLogin = onShowLogin
    }

    var body: some View {
        @Bindable var vm = viewModel
        ZStack(alignment: .bottom) {
            Color.darkGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)

                    Text("Halal AI")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.white)

                    Text("Создайте новый аккаунт")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
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
                                    icon: "envelope.fill",
                                    placeholder: "Email",
                                    text: $vm.email
                                )

                                VStack(alignment: .leading, spacing: 6) {
                                    AuthTextField(
                                        icon: "lock.fill",
                                        placeholder: "Пароль",
                                        text: $vm.password,
                                        isSecure: true
                                    )
                                    if !vm.password.isEmpty && vm.password.count < 8 {
                                        Text("Пароль должен содержать минимум 8 символов")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 4)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    AuthTextField(
                                        icon: "lock.fill",
                                        placeholder: "Подтвердите пароль",
                                        text: $vm.confirmPassword,
                                        isSecure: true
                                    )
                                    if !vm.confirmPassword.isEmpty && vm.password != vm.confirmPassword {
                                        Text("Пароли не совпадают")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 4)
                                    }
                                }
                            }

                            // Register button
                            Button(action: {
                                Task { await vm.register() }
                            }) {
                                HStack {
                                    if vm.authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Зарегистрироваться")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(vm.isFormValid ? Color.darkGreen : Color.greenForeground)
                                .foregroundStyle(.white)
                                .clipShape(.rect(cornerRadius: 14))
                            }
                            .disabled(!vm.isFormValid || vm.authService.isLoading)
                            .opacity((!vm.isFormValid || vm.authService.isLoading) ? 0.6 : 1.0)

                            // Login link
                            HStack(spacing: 4) {
                                Text("Уже есть аккаунт?")
                                    .foregroundStyle(.secondary)
                                Button(action: { onShowLogin?() }) {
                                    Text("Войти")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.darkGreen)
                                }
                            }
                            
                            Button(action: {
                                vm.authManager.continueAsGuest()
                            }) {
                                Text("Продолжить без регистрации")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
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
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage)
        }
    }
}
