//
//  HomeCoordinator.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

enum HomeCoordinator {
    case main
    case scanner
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .main:
            HomeView()
        case .scanner:
            IngredientScannerView()
        }
    }
}
