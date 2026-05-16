//
//  HalalAIApp.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.10.2025.
//

import SwiftUI

@main
struct HalalAIApp: App {
    @State private var languageStore = LanguageStore()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.greenBackground.ignoresSafeArea()
                screenFactory.makeRootView()
                    .preferredColorScheme(.light)
            }
            .environment(languageStore)
        }
    }
}
