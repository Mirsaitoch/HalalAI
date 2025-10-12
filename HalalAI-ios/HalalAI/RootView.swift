//
//  RootView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.10.2025.
//

import SwiftUI

struct RootView: View {
    @StateObject var coordinator = CoordinatorService.shared
    
    var body: some View {
        ZStack {
            NavigationStack(path: $coordinator.path) {
                Group {}
                    .navigationDestination(for: CoordinatorService.Step.self) { destination in
                        destination.view
                    }
            }
            VStack {
                Spacer()
                TabBarView()
            }
        }
    }
}

#Preview {
    RootView()
}
