//
//  HomeCoordinator.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

enum HomeCoordinator {
    case home
    case scanner
    
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            screenFactory.makeHomeView()
        case .scanner:
            screenFactory.makeScannerView()
        }
    }
}
