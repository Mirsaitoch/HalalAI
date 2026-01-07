//
//  NewsScreen.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 22.12.2025.
//

import SwiftUI

struct NewsScreenWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NewsViewController {
        NewsViewController()
    }
    
    func updateUIViewController(
        _ uiViewController: NewsViewController,
        context: Context
    ) {}
}

struct NewsScreen: View {
    var body: some View {
        NewsScreenWrapper()
    }
}

#Preview {
    NewsScreen()
}
