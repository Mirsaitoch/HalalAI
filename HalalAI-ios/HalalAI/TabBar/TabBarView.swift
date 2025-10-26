//
//  TabBarView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct TabBarView: View {
    @StateObject private var coordinator = CoordinatorService.shared
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "brain.head.profile.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        print("Нажата вкладка .chat")
                        withAnimation {
                            coordinator.selectTab(item: .chat)
                        }
                    }
                    .modifier(SelectedIconModifier(tabIsSelected: coordinator.currentSelectedTab == .chat))
                Spacer()
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        print("Нажата вкладка .settings")
                        withAnimation {
                            coordinator.selectTab(item: .settings)
                        }
                    }
                    .modifier(SelectedIconModifier(tabIsSelected: coordinator.currentSelectedTab == .settings))

                Spacer()
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color.tabBar)
            }
            
            Spacer()
        }
    }
}

struct SelectedIconModifier: ViewModifier {
    var tabIsSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(tabIsSelected ? 1.2 : 1.0)
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 100)
                    .fill(tabIsSelected ? Color.greenForegroung : .clear)
                    .frame(width: 70, height: 50)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tabIsSelected)
    }
}

