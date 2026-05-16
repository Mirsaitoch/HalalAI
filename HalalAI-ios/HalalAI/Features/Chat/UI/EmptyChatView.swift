//
//  EmptyChatView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import SwiftUI

struct EmptyChatView: View {
    @State private var isAnimating = false
    @Environment(LanguageStore.self) private var lang
    var chatService: ChatService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 16) {
                Text(lang.t("chat.empty.greeting"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(lang.t("chat.empty.subtitle"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal) {
                    HStack {
                        Spacer()
                        QuickQuestionButton(text: lang.t("chat.empty.q1"), onTap: { chatService.sendMessage(lang.t("chat.empty.q1_message")) })
                        QuickQuestionButton(text: lang.t("chat.empty.q2"), onTap: { chatService.sendMessage(lang.t("chat.empty.q2_message")) })
                        QuickQuestionButton(text: lang.t("chat.empty.q3"), onTap: { chatService.sendMessage(lang.t("chat.empty.q3_message")) })
                        QuickQuestionButton(text: lang.t("chat.empty.q4"), onTap: { chatService.sendMessage(lang.t("chat.empty.q4_message")) })
                        Spacer()
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct QuickQuestionButton: View {
    let text: String
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            Text(text)
                .font(.caption)
                .foregroundStyle(.darkGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.greenForeground)
                }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) {
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}
