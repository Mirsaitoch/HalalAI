//
//  LoginView.swift
//  HalalAI
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel: ViewModel
    @Environment(LanguageStore.self) private var lang
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

                    Text(lang.t("auth.login.subtitle"))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 70)
                .padding(.bottom, 40)

                // White card
                ZStack(alignment: .top) {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 32
                    )
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea(edges: .bottom)

                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 14) {
                                AuthTextField(
                                    icon: "envelope.fill",
                                    placeholder: lang.t("auth.login.email"),
                                    text: $vm.email
                                )
                                .accessibilityIdentifier("login_email_field")

                                AuthTextField(
                                    icon: "lock.fill",
                                    placeholder: lang.t("auth.login.password"),
                                    text: $vm.password,
                                    isSecure: true
                                )
                                .accessibilityIdentifier("login_password_field")
                            }

                            Button(action: {
                                Task { await vm.login() }
                            }) {
                                HStack {
                                    if vm.authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(lang.t("auth.login.button"))
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
                            .accessibilityIdentifier("login_button")

                            HStack(spacing: 4) {
                                Text(lang.t("auth.login.no_account"))
                                    .foregroundStyle(.secondary)
                                Button(action: { onShowRegister?() }) {
                                    Text(lang.t("auth.login.register"))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.darkGreen)
                                }
                                .accessibilityIdentifier("login_register_link")
                            }

                            Button(action: {
                                vm.authManager.continueAsGuest()
                            }) {
                                Text(lang.t("auth.login.guest"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityIdentifier("login_guest_button")
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 36)
                        .padding(.bottom, 40)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .alert(lang.t("common.error"), isPresented: $vm.showError) {
            Button(lang.t("common.ok"), role: .cancel) { }
        } message: {
            Text(vm.errorMessage)
        }
    }
}
