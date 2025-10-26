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
            // Кнопка микрофона
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
            
            // Текстовое поле
            ZStack(alignment: .topLeading) {
                TextField("Напишите вопрос…", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)

//                RoundedRectangle(cornerRadius: 20)
//                    .fill(Color(.systemGray6))
//                    .frame(height: max(40, textHeight))
//                
//                if messageText.isEmpty {
//                    Text("Напишите вопрос…")
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal, 16)
//                        .padding(.vertical, 12)
//                }
//                
//                TextEditor(text: $messageText)
//                    .font(.system(size: 16))
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 8)
//                    .background(Color.clear)
//                    .onChange(of: messageText) { _ in
//                        updateTextHeight()
//                    }
            }
            
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
    
    private func updateTextHeight() {
        let textView = UITextView()
        textView.text = messageText
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.sizeToFit()
        
        let newHeight = max(40, min(120, textView.contentSize.height))
        if newHeight != textHeight {
            withAnimation(.easeInOut(duration: 0.2)) {
                textHeight = newHeight
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        InputBar(
            messageText: .constant(""),
            onSend: {},
            onMicrophoneTap: {}
        )
    }
    .background(Color(.systemGroupedBackground))
}
