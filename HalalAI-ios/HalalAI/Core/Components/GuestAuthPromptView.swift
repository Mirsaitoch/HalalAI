//
//  GuestAuthPromptView.swift
//  HalalAI
//

import SwiftUI

struct GuestAuthPromptView: View {
    let featureName: String
    let authManager: AuthManager
    @Environment(LanguageStore.self) private var lang

    var body: some View {
        ZStack {
            Color.greenBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.darkGreen)

                VStack(spacing: 8) {
                    Text(lang.t("guest.title"))
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.darkGreen)

                    Text(lang.t("guest.subtitle_prefix") + featureName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    authManager.logout()
                }) {
                    Text(lang.t("guest.sign_in"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.darkGreen)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
            }
            .padding()
        }
    }
}
