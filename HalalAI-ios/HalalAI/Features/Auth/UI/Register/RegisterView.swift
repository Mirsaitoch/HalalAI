//
//  RegisterView.swift
//  HalalAI
//

import SwiftUI

struct RegisterView: View {
    @State private var viewModel: ViewModel
    @Environment(LanguageStore.self) private var lang
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
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)

                    Text("Halal AI")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.white)

                    Text(lang.t("auth.register.subtitle"))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 70)
                .padding(.bottom, 40)

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
                                .accessibilityIdentifier("register_email_field")

                                VStack(alignment: .leading, spacing: 6) {
                                    AuthTextField(
                                        icon: "lock.fill",
                                        placeholder: lang.t("auth.login.password"),
                                        text: $vm.password,
                                        isSecure: true
                                    )
                                    .accessibilityIdentifier("register_password_field")
                                    if !vm.password.isEmpty && vm.password.count < 8 {
                                        Text(lang.t("auth.register.password_hint"))
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 4)
                                            .accessibilityIdentifier("register_password_error")
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    AuthTextField(
                                        icon: "lock.fill",
                                        placeholder: lang.t("auth.register.confirm_password"),
                                        text: $vm.confirmPassword,
                                        isSecure: true
                                    )
                                    .accessibilityIdentifier("register_confirm_password_field")
                                    if !vm.confirmPassword.isEmpty && vm.password != vm.confirmPassword {
                                        Text(lang.t("auth.register.password_mismatch"))
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 4)
                                            .accessibilityIdentifier("register_password_mismatch_error")
                                    }
                                }
                            }

                            Button(action: {
                                Task { await vm.register() }
                            }) {
                                HStack {
                                    if vm.authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(lang.t("auth.register.button"))
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
                            .accessibilityIdentifier("register_button")

                            HStack(spacing: 4) {
                                Text(lang.t("auth.register.has_account"))
                                    .foregroundStyle(.secondary)
                                Button(action: { onShowLogin?() }) {
                                    Text(lang.t("auth.login.button"))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.darkGreen)
                                }
                                .accessibilityIdentifier("register_login_link")
                            }

                            Button(action: {
                                vm.authManager.continueAsGuest()
                            }) {
                                Text(lang.t("auth.register.guest"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityIdentifier("register_guest_button")
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
