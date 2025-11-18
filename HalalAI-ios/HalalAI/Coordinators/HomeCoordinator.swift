//
//  HomeCoordinator.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

enum HomeCoordinator {
    case main
    
    var view: some View {
        switch self {
        case .main:
            return HomeView()
        }
    }
}
