//
//  ErrorMessageView.swift
//  HalalAI
//
//  Extracted from ChatView.swift
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Ошибка соединения")
                        .font(.headline)
                        .foregroundStyle(.red)
                }

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                HStack {
                    Button(action: onRetry) {
                        Text("Повторить отправку")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.1))
                            }
                    }

                    Button("Копировать", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = message
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    }
            }

            Spacer()
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
    }
}
