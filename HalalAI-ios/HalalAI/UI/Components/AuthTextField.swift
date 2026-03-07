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
                .foregroundColor(.darkGreen)
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
            .foregroundColor(.primary)

            if isSecure {
                Button(action: { showText.toggle() }) {
                    Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}
