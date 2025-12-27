//
//  View+hideKeyboard.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 27.12.2025.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
