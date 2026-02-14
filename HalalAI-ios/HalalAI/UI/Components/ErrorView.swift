//
//  ErrorView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 14.02.2026.
//

import SwiftUI

struct ErrorView: View {
    var message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorView(message: "Ошибка")
}
