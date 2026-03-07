//
//  HomeView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

struct HomeView: View {
    @Environment(Coordinator.self) var coordinator
    var viewModel: ViewModel
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VerseView(verseService: viewModel.verseService)
                
                if viewModel.authManager.isGuest {
                    GuestBannerView {
                        viewModel.authManager.logout()
                    }
                }
                
                PrayerTimesCardView(viewModel: viewModel.prayerCardViewModel)

                ImageTextComponent(
                    componentSize: .large,
                    image: .scan,
                    title: "Сканировать состав",
                    description: "Проверь ингредиенты на халяльность",
                    locked: viewModel.authManager.isGuest
                )
                .onTapGesture {
                    guard !viewModel.authManager.isGuest else { return }
                    coordinator.nextStep(step: .Home(.scanner))
                }

                HStack(spacing: 8) {
                    ImageTextComponent(
                        componentSize: .medium,
                        image: .quran,
                        title: "Чат с AI",
                        description: "Задай вопрос",
                        locked: viewModel.authManager.isGuest
                    )
                    .onTapGesture {
                        guard !viewModel.authManager.isGuest else { return }
                        coordinator.selectTab(item: .chat)
                    }
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
                .onTapGesture {
                    withAnimation {
                        coordinator.nextStep(step: .Home(.quran))
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        .background {
            Color.greenBackground.ignoresSafeArea()
        }
    }
}
