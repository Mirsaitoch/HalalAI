//
//  SettingsCoordinator.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

enum SettingsCoordinator {
    case settings
    
    @MainActor
    var view: some View {
        switch self {
        case .settings:
            screenFactory.makeSettingsView()
        }
    }
}
