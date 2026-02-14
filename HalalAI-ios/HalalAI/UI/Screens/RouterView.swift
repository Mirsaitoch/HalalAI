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
                coordinator.rootView
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

