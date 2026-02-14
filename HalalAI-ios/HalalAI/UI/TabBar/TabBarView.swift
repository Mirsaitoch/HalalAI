//
//  TabBarView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct TabBarView: View {
    @Environment(Coordinator.self) var coordinator
    var body: some View {
        HStack {
            ZStack {
                SelectedCapsule(selectedTab: coordinator.currentSelectedTab)
                HStack(spacing: 50) {
                    TabBarIcon(tab: .home, coordinator: coordinator)
                        .id(0)
                    TabBarIcon(tab: .chat, coordinator: coordinator)
                        .id(1)
                    TabBarIcon(tab: .settings, coordinator: coordinator)
                        .id(2)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color.tabBar)
                .opacity(0.9)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

struct SelectedCapsule: View {
    var selectedTab: TabBarItem
    private let positions: [CGFloat] = [-100.0, 0, 100.0]
    var body: some View {
        RoundedRectangle(cornerRadius: 100)
            .fill(Color.greenForeground)
            .frame(width: 70, height: 50)
            .offset(x: positions[selectedTab.model.indexInTab])
            .animation(.bouncy(extraBounce: 0.1), value: selectedTab.model.indexInTab)
    }
}

struct TabBarIcon: View {
    let tab: TabBarItem
    var coordinator: Coordinator
    var body: some View {
        Image(uiImage: tab.model.image)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding(10)
            .scaleEffect(coordinator.currentSelectedTab == tab ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: coordinator.currentSelectedTab)
            .onTapGesture {
                coordinator.selectTab(item: tab)
            }
    }
}
