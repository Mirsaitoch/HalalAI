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
                    .foregroundColor(.greenForeground)

                VStack(spacing: 8) {
                    Text("Нужна авторизация")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.greenForeground)

                    Text("Войдите или зарегистрируйтесь,\nчтобы использовать \(featureName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("Войти")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.greenForeground)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("Зарегистрироваться")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(.greenForeground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.greenForeground, lineWidth: 2)
                            )
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding()
        }
    }
}
