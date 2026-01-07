//
//  HomeView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

struct HomeView: View {
    @Environment(Coordinator.self) var coordinator

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                ImageTextComponent(
                    componentSize: .large,
                    image: .scan,
                    title: "Сканировать состав",
                    description: "Проверь ингредиенты на халяльность"
                )
                .onTapGesture {
                    withAnimation {
                        coordinator.nextStep(step: .Home(.scanner))
                    }
                }
                
                HStack {
                    ImageTextComponent(
                        componentSize: .medium,
                        image: .quran,
                        title: "Чат с AI",
                        description: "Задай вопрос"
                    )
                    .onTapGesture {
                        withAnimation {
                            coordinator.selectTab(item: .chat)
                        }
                    }
                    Spacer()
                    ImageTextComponent(
                        componentSize: .medium,
                        image: .map,
                        title: "Найти заведение",
                        description: "Халяль места рядом"
                    )
                }
                
                ImageTextComponent(
                    componentSize: .large,
                    image: .mosque,
                    title: "Изучай Ислам",
                    description: "Суры и Аяты из Корана"
                )
            }
        }
        .padding(.horizontal, 15)
        .background {
            Color.greenBackground.ignoresSafeArea()
        }
    }
}

#Preview {
    HomeView()
}
