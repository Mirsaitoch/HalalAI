//
//  HomeViewModelTests.swift
//  HalalAITests
//

import Foundation
import CoreLocation
import Testing
@testable import HalalAI

@MainActor
struct HomeViewModelTests {

    @Test("ViewModel stores injected dependencies")
    func storesDependencies() {
        let (vm, verseService, authManager) = makeSUT()

        #expect(vm.authManager.isAuthenticated == false)

        verseService.verseOfTheDay = Verse(
            id: 1, suraIndex: 1, suraTitle: "Аль-Фатиха",
            suraSubtitle: "Открывающая", verseNumber: 1, text: "Бисмиллях"
        )

        #expect(vm.verseService.verseOfTheDay?.text == "Бисмиллях")

        authManager.saveAuth(AuthResponse(token: "t", type: "Bearer", userId: 1, email: "e@e.com"))
        #expect(vm.authManager.isAuthenticated == true)
    }

    // MARK: - Helpers

    private func makeSUT() -> (HomeView.ViewModel, MockVerseService, MockAuthManager) {
        let verseService = MockVerseService()
        let locationService = MockLocationService()
        locationService.currentLocation = CLLocation(latitude: 55.75, longitude: 37.62)

        let prayerService = MockPrayerTimeService()
        let settingsStore = PrayerSettingsStore()
        let prayerVM = PrayerTimesCardView.ViewModel(
            locationService: locationService,
            prayerTimeService: prayerService,
            settingsStore: settingsStore
        )

        let authManager = MockAuthManager()
        let vm = HomeView.ViewModel(
            verseService: verseService,
            prayerCardViewModel: prayerVM,
            authManager: authManager
        )
        return (vm, verseService, authManager)
    }
}
