//
//  CoordinatorService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

final class CoordinatorService: ObservableObject {
    static let shared = CoordinatorService()
    
    static func createForTesting() -> CoordinatorService {
        return CoordinatorService()
    }
    
    @Published var path: [Step] = []
    var homeTabPath: [Step] = []
    var chatTabPath: [Step] = []
    var settingsTabPath: [Step] = []
    
    var currentSelectedTab: TabBarItem = .chat
    var currentStep: Step?
    
    private init() {}
    
    private init(forTesting: Bool) {}
    
    enum Step: Hashable, Equatable {
        case Chat(_ val: ChatCoordinator)
        case Settings(_ val: SettingsCoordinator)
        case Home(_ val: HomeCoordinator)
        
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
    
    func nextStep(step: Step) {
        Task { @MainActor in
            currentStep = step
            path.append(step)
        }
    }
    
    func selectTab(item: TabBarItem) {
        Task { @MainActor in
            switch item {
            case .chat:
                if currentSelectedTab == .chat {
                    print("Значение на вкладке .chat сброшено")
                    path = [.Chat(.chat)]
                    chatTabPath = [.Chat(.chat)]
                    return
                } else {
                    savePreviousTabPath()
                    if chatTabPath.isEmpty || path.isEmpty {
                        path = [.Chat(.chat)]
                    } else {
                        path = chatTabPath
                    }
                    print("Нажата вкладка Chat, path: \(path)")
                }
                currentSelectedTab = .chat
            case .settings:
                if currentSelectedTab == .settings {
                    print("Значение на вкладке .settings сброшено")
                    path = [.Settings(.settings)]
                    settingsTabPath = [.Settings(.settings)]
                    return
                } else {
                    savePreviousTabPath()
                    if settingsTabPath.isEmpty || path.isEmpty {
                        path = [.Settings(.settings)]
                    } else {
                        path = settingsTabPath
                    }
                    print("Нажата вкладка Setting, path: \(path)")
                }
                currentSelectedTab = .settings
            case .home:
                if currentSelectedTab == .home {
                    print("Значение на вкладке .home сброшено")
                    path = [.Home(.main)]
                    homeTabPath = [.Home(.main)]
                    return
                } else {
                    savePreviousTabPath()
                    if homeTabPath.isEmpty || path.isEmpty {
                        path = [.Home(.main)]
                    } else {
                        path = homeTabPath
                    }
                    print("Нажата вкладка Main, path: \(path)")
                }
                currentSelectedTab = .home
            }
            print("Выбрана вкладка \(currentSelectedTab)")
            print("path: \(path)")
        }
    }
    
    func toRoot() {
        Task { @MainActor in
            currentStep = nil
            path = []
        }
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
}
