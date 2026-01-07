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
            HStack(spacing: 50) {
                TabBarIcon(systemName: "house.fill", tab: .home, coordinator: coordinator)
                TabBarIcon(systemName: "brain.head.profile.fill", tab: .chat, coordinator: coordinator)
                TabBarIcon(systemName: "gearshape.fill", tab: .settings, coordinator: coordinator)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color.tabBar)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
        }
}

struct TabBarIcon: View {
    let systemName: String
    let tab: TabBarItem
    var coordinator: Coordinator

    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(isSelected ? Color.greenForeground : .clear)
                    .frame(width: 70, height: 50)
            )
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    coordinator.selectTab(item: tab)
                }
            }
    }

    private var isSelected: Bool {
        coordinator.currentSelectedTab == tab
    }
}

