//
//  InputBar.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import SwiftUI

struct InputBar: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let onMicrophoneTap: () -> Void
    @State private var textHeight: CGFloat = 40
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Кнопка микрофона, пока ее отключем
            if false {
                Button(action: {
                    HapticFeedback.medium()
                    onMicrophoneTap()
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        }
                }
            }
            
            TextField("Напишите вопрос…", text: $messageText)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
            
            // Кнопка отправки
            Button(action: {
                HapticFeedback.light()
                onSend()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
