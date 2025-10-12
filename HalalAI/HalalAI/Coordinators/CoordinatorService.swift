//
//  CoordinatorService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

class CoordinatorService: ObservableObject {
    static let shared = CoordinatorService()
    
    @Published var path: [Step] = []
    @Published var chatTabPath: [Step] = []
    @Published var settingsTabPath: [Step] = []
    @Published var currentSelectedTab: TabBarItem = .chat

    var currentStep: Step?
    
    private init() {}
    
    enum Step: Hashable, Equatable {
        case Chat(_ val: ChatCoordinator)
        case Settings(_ val: SettingsCoordinator)
        
        var view: some View {
            Group {
                switch self {
                case .Chat(let value): value.view
                case .Settings(let value): value.view
                }
            }
        }
    }
    
    func nextStep(step: Step) {
        currentStep = step
        path.append(step)
    }
    
    func selectTab(item: TabBarItem) {
        Task { @MainActor in
            switch item {
            case .chat:
                if currentSelectedTab == .chat {
                    print("Значение на вкладке .chat сброшено")
                    path = []
                    chatTabPath = []
                    return
                } else {
                    savePreviousTabPath()
                    path = chatTabPath
                }
                currentSelectedTab = .chat
            case .settings:
                if currentSelectedTab == .settings {
                    print("Значение на вкладке .settings сброшено")
                    path = []
                    settingsTabPath = []
                    return
                } else {
                    savePreviousTabPath()
                    path = settingsTabPath
                }
                currentSelectedTab = .settings
            }
            print("Выбрана вкладка \(currentSelectedTab)")
        }
    }
    
    func toRoot() {
        currentStep = .Chat(.chat)
        path = []
    }
    
    // MARK: - Private
    
    private func savePreviousTabPath() {
        switch currentSelectedTab {
        case .chat:
            chatTabPath = path
        case .settings:
            settingsTabPath = path
        }
    }
}
