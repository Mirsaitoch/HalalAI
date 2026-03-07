//
//  CoordinatorService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

enum Step: Hashable, Equatable {
    case Chat(_ val: ChatCoordinator)
    case Settings(_ val: SettingsCoordinator)
    case Home(_ val: HomeCoordinator)

    @MainActor
    var view: some View {
        Group {
            switch self {
            case .Chat(let value): value.view
            case .Settings(let value): value.view
            case .Home(let value): value.view
            }
        }
    }
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
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            path = []
            currentSelectedTab = item
        }
    }

    @ViewBuilder
    func build(step: Step) -> some View {
        switch step {
        case .Chat(let value): value.view
        case .Settings(let value): value.view
        case .Home(let value): value.view
        }
    }
}
