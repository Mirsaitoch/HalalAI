//
//  ChatCoordinator.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

enum ChatCoordinator {
    case chat
    
    @MainActor
    var view: some View {
        switch self {
        case .chat:
            screenFactory.makeChatView()
        }
    }
}
