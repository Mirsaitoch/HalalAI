//
//  RouterView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import SwiftUI

struct RouterView<Content: View>: View {
    @StateObject var coordinator = CoordinatorService.shared
    private let content: Content
    
    @inlinable
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            NavigationStack(path: $coordinator.path) {
                content
                    .navigationDestination(for: CoordinatorService.Step.self) { destination in
                        destination.view
                            .navigationBarBackButtonHidden()
                    }
            }
            TabBarView()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            coordinator.selectTab(item: .home)
        }
    }
}
