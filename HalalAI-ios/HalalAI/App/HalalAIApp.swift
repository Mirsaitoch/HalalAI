//
//  HalalAIApp.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.10.2025.
//

import SwiftUI

@main
struct HalalAIApp: App {
    //нужно для тестирования камеры
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
        loadRocketSimConnect()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.greenBackground.ignoresSafeArea()
                RootView()
            }
        }
    }
}
