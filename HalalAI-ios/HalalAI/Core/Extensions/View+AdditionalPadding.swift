//
//  View+AdditionalPadding.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 14.02.2026.
//

import SwiftUI

struct AdditionalPaddingModifier: ViewModifier {
    let shouldShow: Bool
    let height: Int
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: CGFloat(shouldShow ? height : .zero))
            }
    }
}

extension View {
    func additionalPaddingIfNeeded(_ shouldShow: Bool, _ height: Int) -> some View {
        self.modifier(AdditionalPaddingModifier(shouldShow: shouldShow, height: height))
    }
}
