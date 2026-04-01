//
//  ScreenFactory.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 07.01.2026.
//

import Foundation
import SwiftUI

protocol ScreenFactory {
    func makeLoginView(path: Binding<[AuthCoordinator]>) -> LoginView
    func makeRegisterView(path: Binding<[AuthCoordinator]>) -> RegisterView
    func makeRootView() -> RootView
    func makeSettingsView() -> SettingsView
    func makeChatView() -> ChatView
    func makeScannerView() -> ScannerView
    func makeHomeView() -> HomeView
    func makeQuranListView() -> QuranListView
    func makeSuraReaderView(suraIndex: Int) -> SuraReaderView
    func makePrayerNotificationSettingsView() -> PrayerNotificationSettingsView
}

@MainActor
let screenFactory = ScreenFactoryImpl()

@MainActor
final class ScreenFactoryImpl {
    fileprivate init() {}
    fileprivate let dc = DependencyContainer()
    
    func makeLoginView(path: Binding<[AuthCoordinator]>) -> LoginView {
        return LoginView(authManager: dc.authManager, authService: dc.authService) {
            path.wrappedValue = [.register]
        }
    }
    
    func makeRegisterView(path: Binding<[AuthCoordinator]>) -> RegisterView {
        return RegisterView(authManager: dc.authManager, authService: dc.authService) {
            path.wrappedValue = []
        }
    }
    
    func makeRootView() -> RootView {
        RootView(authManager: dc.authManager)
    }
    
    func makeSettingsView() -> SettingsView {
        return SettingsView(chatService: dc.chatService, authManager: dc.authManager)
    }
    
    func makeChatView() -> ChatView {
        return ChatView(chatService: dc.chatService, authManager: dc.authManager)
    }

    func makeScannerView() -> ScannerView {
        return ScannerView(ingredientService: dc.ingredientService, authManager: dc.authManager)
    }
    
    func makeHomeView() -> HomeView {
        return HomeView(
            verseService: dc.verseService,
            locationService: dc.locationService,
            prayerTimeService: dc.prayerTimeService,
            settingsStore: dc.prayerSettingsStore,
            authManager: dc.authManager
        )
    }

    func makePrayerNotificationSettingsView() -> PrayerNotificationSettingsView {
        return PrayerNotificationSettingsView(
            settingsStore: dc.prayerSettingsStore,
            notificationService: dc.prayerNotificationService,
            locationService: dc.locationService
        )
    }

    func makeQuranListView() -> QuranListView {
        return QuranListView(quranStorage: dc.quranStorage)
    }

    func makeSuraReaderView(suraIndex: Int) -> SuraReaderView {
        return SuraReaderView(suraIndex: suraIndex, quranStorage: dc.quranStorage)
    }

    func makeHalalMapView() -> HalalMapView {
        return HalalMapView(placesService: dc.halalPlacesService, locationService: dc.locationService)
    }
}

@MainActor
final class DependencyContainer {
    fileprivate var authManager: AuthManager
    fileprivate var authService: AuthService
    fileprivate var chatService: ChatService
    fileprivate var ingredientService: IngredientService
    fileprivate var verseService: VerseService
    fileprivate var quranStorage: QuranStorageService
    fileprivate var locationService: LocationService
    fileprivate var prayerTimeService: PrayerTimeService
    fileprivate var prayerSettingsStore: PrayerSettingsStore
    fileprivate var prayerNotificationService: PrayerNotificationService
    fileprivate var halalPlacesService: HalalPlacesService

    init() {
        self.authManager = AuthManagerImpl()
        self.authService = AuthServiceImpl()
        self.chatService = ChatServiceImpl(authManager: authManager)
        self.ingredientService = IngredientServiceImpl()
        self.verseService = VerseServiceImpl()
        self.quranStorage = QuranStorageServiceImpl()
        self.locationService = LocationServiceImpl()
        self.prayerTimeService = PrayerTimeServiceImpl()
        self.prayerSettingsStore = PrayerSettingsStore()
        self.prayerNotificationService = PrayerNotificationServiceImpl(prayerTimeService: prayerTimeService)
        self.halalPlacesService = HalalPlacesServiceImpl()
    }
}
