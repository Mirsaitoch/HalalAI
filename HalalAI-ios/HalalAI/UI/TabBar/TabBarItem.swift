//
//  TabBarItem.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//
import SwiftUI

struct TabBarItemModel {
    let indexInTab: Int
    let name: String
    let image: UIImage
}

enum TabBarItem {
    case home
    case chat
    case settings

    var model: TabBarItemModel {
        switch self {
        case .home:
            return TabBarItemModel(
                indexInTab: 0,
                name: "Homepage",
                image: UIImage(systemName: "house.fill")!
            )
        case .chat:
            return TabBarItemModel(
                indexInTab: 1,
                name: "Chat",
                image: UIImage(systemName: "brain.head.profile.fill")!
            )
        case .settings:
            return TabBarItemModel(
                indexInTab: 2,
                name: "Settings",
                image: UIImage(systemName: "gearshape.fill")!
            )
        }
    }
}
