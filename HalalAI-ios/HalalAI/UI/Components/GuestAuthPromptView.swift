//
//  GuestAuthPromptView.swift
//  HalalAI
//

import SwiftUI

struct GuestAuthPromptView: View {
    let featureName: String
    let authManager: AuthManager

    var body: some View {
        ZStack {
            Color.greenBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.darkGreen)

                VStack(spacing: 8) {
                    Text("Нужна авторизация")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.darkGreen)

                    Text("Войдите в аккаунт,\nчтобы использовать \(featureName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    authManager.logout()
                }) {
                    Text("Войти")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.darkGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            .padding()
        }
    }
}
