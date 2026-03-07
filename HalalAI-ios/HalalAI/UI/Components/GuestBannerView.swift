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
                    .font(.system(size: 28))
                    .foregroundColor(.darkGreen)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Войдите в аккаунт")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.darkGreen)
                    Text("Чтобы использовать чат и сканер")
                        .font(.system(size: 13))
                        .foregroundColor(.darkGreen)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.greenForeground)
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
