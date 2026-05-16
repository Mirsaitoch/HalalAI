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
        notificationService: PrayerNotificationService,
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
                notificationService: notificationService,
                locationService: locationService,
                settingsStore: settingsStore,
                authManager: authManager
            )
        )
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VerseView(verseService: viewModel.verseService)
                
                if viewModel.authManager.isGuest {
                    GuestBannerView {
                        viewModel.authManager.logout()
                    }
                }
                
                PrayerTimesCardView(viewModel: viewModel.prayerCardViewModel)

                Button {
//                    guard !viewModel.authManager.isGuest else { return }
                    coordinator.nextStep(step: .home(.scanner))
                } label: {
                    ImageTextComponent(
                        componentSize: .large,
                        image: .scan,
                        title: "Сканировать состав",
                        description: "Проверь ингредиенты на халяльность",
//                        locked: viewModel.authManager.isGuest
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home_scanner_button")

                HStack(spacing: 8) {
                    Button {
                        guard !viewModel.authManager.isGuest else { return }
                        coordinator.selectTab(item: .chat)
                    } label: {
                        ImageTextComponent(
                            componentSize: .medium,
                            image: .quran,
                            title: "Чат с AI",
                            description: "Задай вопрос",
                            locked: viewModel.authManager.isGuest
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_chat_button")

                    Button {
                        coordinator.nextStep(step: .home(.halalMap))
                    } label: {
                        ImageTextComponent(
                            componentSize: .medium,
                            image: .map,
                            title: "Найти заведение",
                            description: "Халяль места рядом"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_map_button")
                }

                Button {
                    withAnimation {
                        coordinator.nextStep(step: .home(.quran))
                    }
                } label: {
                    ImageTextComponent(
                        componentSize: .large,
                        image: .mosque,
                        title: "Изучай Ислам",
                        description: "Суры и Аяты из Корана"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home_quran_button")
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 24)
        .background {
            Color.greenBackground.ignoresSafeArea()
        }
        .task {
            await viewModel.rescheduleNotifications()
        }
    }
}
