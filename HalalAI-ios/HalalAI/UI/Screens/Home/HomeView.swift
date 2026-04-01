//
//  HomeView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

struct HomeView: View {
    @Environment(Coordinator.self) var coordinator
    @State private var viewModel: ViewModel

    init(
        verseService: VerseService,
        locationService: LocationService,
        prayerTimeService: PrayerTimeService,
        settingsStore: PrayerSettingsStore,
        authManager: AuthManager
    ) {
        let prayerCardVM = PrayerTimesCardView.ViewModel(
            locationService: locationService,
            prayerTimeService: prayerTimeService,
            settingsStore: settingsStore
        )
        _viewModel = State(
            initialValue: ViewModel(
                verseService: verseService,
                prayerCardViewModel: prayerCardVM,
                authManager: authManager
            )
        )
    }

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
                    .onTapGesture {
                        coordinator.nextStep(step: .Home(.halalMap))
                    }
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
        .padding(.horizontal, 24)
        .background {
            Color.greenBackground.ignoresSafeArea()
        }
    }
}
