//
//  AuthTextField.swift
//  HalalAI
//

import SwiftUI

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State private var showText: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.darkGreen)
                .frame(width: 20)

            Group {
                if isSecure && !showText {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
            }
            .foregroundStyle(.primary)

            if isSecure {
                Button(showText ? "Скрыть пароль" : "Показать пароль",
                       systemImage: showText ? "eye.slash.fill" : "eye.fill",
                       action: { showText.toggle() })
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}
