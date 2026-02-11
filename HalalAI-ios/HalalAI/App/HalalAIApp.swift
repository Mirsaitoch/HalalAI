//
//  HalalAIApp.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.10.2025.
//

import SwiftUI

@main
struct HalalAIApp: App {
    // Нужно для тестирования камеры (RocketSim)
    private func loadRocketSimConnect() {
        #if DEBUG
        guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
        #endif
    }
    
    init() {
        // тоже нужно для тестирования камеры
        loadRocketSimConnect()
    }
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.greenBackground.ignoresSafeArea()
                screenFactory.makeRootView()
            }
        }
    }
}
