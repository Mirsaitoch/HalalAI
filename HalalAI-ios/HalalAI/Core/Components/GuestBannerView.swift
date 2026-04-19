//
//  GuestBannerView.swift
//  HalalAI
//

import SwiftUI

struct GuestBannerView: View {
    let onLogin: () -> Void

    var body: some View {
        Button(action: onLogin) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.darkGreen)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Войдите в аккаунт")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.darkGreen)
                    Text("Чтобы использовать чат и сканер")
                        .font(.caption)
                        .foregroundStyle(.darkGreen)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.greenForeground)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.greenForeground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.greenForeground.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
