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
    private var tabBarHeight = 80

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $coordinator.path) {
                tabRootView
                    .additionalPaddingIfNeeded(shouldShowTabBar, tabBarHeight)
                    .navigationDestination(for: Step.self) { step in
                        coordinator.build(step: step)
                            .navigationBarBackButtonHidden()
                            .additionalPaddingIfNeeded(shouldShowTabBar, tabBarHeight)
                    }
            }

            if shouldShowTabBar {
                TabBarView()
                    .edgesIgnoringSafeArea(.bottom)
                    .transition(.push(from: .bottom))
            }
        }
        .environment(coordinator)
        .ignoresSafeArea(.keyboard, edges: .bottom)
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

    @ViewBuilder
    private var tabRootView: some View {
        switch coordinator.currentSelectedTab {
        case .home:
            coordinator.build(step: .Home(.home))
        case .chat:
            coordinator.build(step: .Chat(.chat))
        case .settings:
            coordinator.build(step: .Settings(.settings))
        }
    }

    private var shouldShowTabBar: Bool {
        !isKeyboardVisible
    }
}
