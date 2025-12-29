//
//  RouterView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import SwiftUI

struct RouterView: View {
    @StateObject var coordinator = Coordinator()
    
    var body: some View {
        VStack {
            NavigationStack(path: $coordinator.path) {
                coordinator.rootView
                    .navigationDestination(for: Step.self) { step in
                        coordinator.build(step: step)
                            .navigationBarBackButtonHidden()
                    }
            }
            TabBarView()
        }
        .environmentObject(coordinator)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            coordinator.selectTab(item: .home)
        }
    }
}
