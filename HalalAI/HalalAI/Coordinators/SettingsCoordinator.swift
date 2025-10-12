//
//  SettingsCoordinator.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

enum SettingsCoordinator {
    case settings
    
    var view: some View {
        switch self {
        case .settings:
            return SettingsView()
        }
    }
}
