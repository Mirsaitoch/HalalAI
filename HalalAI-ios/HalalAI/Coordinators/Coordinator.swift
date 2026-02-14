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
    var path: [Step] = [.Home(.home)]
    var currentSelectedTab: TabBarItem = .home
    
    private var homeTabPath: [Step] = []
    private var chatTabPath: [Step] = []
    private var settingsTabPath: [Step] = []
    
    var currentStep: Step?
    
    init() {}
        
    func nextStep(step: Step) {
        currentStep = step
        path.append(step)
        print("nextStep актуальный path: \(path)")
    }
    
    func dismiss() {
        if path.count > 1 {
            path.removeLast()
            currentStep = path.last
            print("dismiss актуальный path: \(path)")
        } else {
            print("dismiss невозможно вернуться назад, тк path(количество <= 1): \(path)")
        }
    }
    
    var rootStep: Step {
        switch currentSelectedTab {
        case .chat:
            return .Chat(.chat)
        case .settings:
            return .Settings(.settings)
        case .home:
            return .Home(.home)
        }
    }
    
    var rootView: AnyView {
        AnyView(build(step: rootStep))
    }
    
    @ViewBuilder
    func build(step: Step) -> some View {
        switch step {
        case .Chat(let value): value.view
        case .Settings(let value): value.view
        case .Home(let value): value.view
        }
    }
    func selectTab(item: TabBarItem) {
        // Повторное нажатие на вкладку - возврат к корню стека этой вкладки
        if item == currentSelectedTab {
            path = rootPathForItem(item)
            savePath(path, for: item)
            return
        }
        
        savePreviousTabPath()
        currentSelectedTab = item
        path = restorePath(for: item)
    }
    
    func toRoot() {
        currentStep = nil
        path = []
    }
    
    // MARK: - Private

    private func savePreviousTabPath() {
        switch currentSelectedTab {
        case .chat:
            chatTabPath = path
        case .settings:
            settingsTabPath = path
        case .home:
            homeTabPath = path
        }
    }
    
    private func restorePath(for tab: TabBarItem) -> [Step] {
        switch tab {
        case .chat:
            return chatTabPath
        case .settings:
            return settingsTabPath
        case .home:
            return homeTabPath
        }
    }
    
    private func savePath(_ newPath: [Step], for tab: TabBarItem) {
        switch tab {
        case .chat:
            chatTabPath = newPath
        case .settings:
            settingsTabPath = newPath
        case .home:
            homeTabPath = newPath
        }
    }
    
    private func rootPathForItem(_ item: TabBarItem) -> [Step] {
        switch item {
        case .chat:
            return [.Chat(.chat)]
        case .settings:
            return [.Settings(.settings)]
        case .home:
            return [.Home(.home)]
        }
    }
}
