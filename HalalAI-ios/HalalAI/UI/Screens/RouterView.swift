//
//  RouterView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import SwiftUI
import Combine

struct RouterView: View {
    @State var coordinator = Coordinator()
    @State private var isKeyboardVisible = false

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.rootView
                .navigationDestination(for: Step.self) { step in
                    coordinator.build(step: step)
                        .navigationBarBackButtonHidden()
                }
                .safeAreaInset(edge: .bottom) {
                    if shouldShowTabBar {
                        TabBarView()
                    }
                }
        }
        .environment(coordinator)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            coordinator.selectTab(item: .home)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                isKeyboardVisible = false
            }
        }
    }
    
    private var shouldShowTabBar: Bool {
        !isKeyboardVisible
    }
}

