//
//  CoordinatorService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

enum Step: Hashable, Equatable {
    case chat(_ val: ChatCoordinator)
    case settings(_ val: SettingsCoordinator)
    case home(_ val: HomeCoordinator)
}

@MainActor
@Observable
final class Coordinator {
    var path: [Step] = []
    var currentSelectedTab: TabBarItem = .home

    init() {}

    func nextStep(step: Step) {
        path.append(step)
    }

    func dismiss() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func toRoot() {
        path = []
    }

    func selectTab(item: TabBarItem) {
        if item == currentSelectedTab {
            path = []
            return
        }
        path = []
        currentSelectedTab = item
    }

    @ViewBuilder
    func build(step: Step) -> some View {
        switch step {
        case .chat(let value): value.view
        case .settings(let value): value.view
        case .home(let value): value.view
        }
    }
}
