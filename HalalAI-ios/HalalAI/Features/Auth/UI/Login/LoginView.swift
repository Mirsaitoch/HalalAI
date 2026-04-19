//
//  LoginView.swift
//  HalalAI
//


import SwiftUI

struct LoginView: View {
    @State private var viewModel: ViewModel
    private let onShowRegister: (() -> Void)?

    init(
        authManager: AuthManager,
        authService: AuthService,
        onShowRegister: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: ViewModel(authManager: authManager, authService: authService))
        self.onShowRegister = onShowRegister
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

                    Text("Войдите в свой аккаунт")
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

                                AuthTextField(
                                    icon: "lock.fill",
                                    placeholder: "Пароль",
                                    text: $vm.password,
                                    isSecure: true
                                )
                            }

                            // Login button
                            Button(action: {
                                Task { await vm.login() }
                            }) {
                                HStack {
                                    if vm.authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Войти")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(vm.isDisable ? Color.greenForeground : Color.darkGreen)
                                .foregroundStyle(.white)
                                .clipShape(.rect(cornerRadius: 14))
                            }
                            .disabled(vm.isDisable)
                            .opacity(vm.isDisable ? 0.6 : 1.0)

                            // Register link
                            HStack(spacing: 4) {
                                Text("Нет аккаунта?")
                                    .foregroundStyle(.secondary)
                                Button(action: { onShowRegister?() }) {
                                    Text("Зарегистрироваться")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.darkGreen)
                                }
                            }

                            // Guest login
                            Button(action: {
                                vm.authManager.continueAsGuest()
                            }) {
                                Text("Продолжить без аккаунта")
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
