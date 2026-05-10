//
//  HomeViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 14.02.2026.
//

import Foundation

extension HomeView {
    @Observable
    @MainActor
    final class ViewModel {
        var verseService: VerseService
        var prayerCardViewModel: PrayerTimesCardView.ViewModel
        var authManager: AuthManager

        private let notificationService: PrayerNotificationService
        private let locationService: LocationService
        private let settingsStore: PrayerSettingsStore

        init(
            verseService: VerseService,
            prayerCardViewModel: PrayerTimesCardView.ViewModel,
            notificationService: PrayerNotificationService,
            locationService: LocationService,
            settingsStore: PrayerSettingsStore,
            authManager: AuthManager
        ) {
            self.verseService = verseService
            self.prayerCardViewModel = prayerCardViewModel
            self.notificationService = notificationService
            self.locationService = locationService
            self.settingsStore = settingsStore
            self.authManager = authManager
        }

        func rescheduleNotifications() async {
            await notificationService.rescheduleIfNeeded(
                settings: settingsStore.settings,
                location: locationService.currentLocation
            )
        }

        deinit {
            print("deinit HomeViewModel")
        }
    }
}
