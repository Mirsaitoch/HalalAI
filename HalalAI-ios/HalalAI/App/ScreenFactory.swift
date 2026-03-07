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
        let viewModel = LoginView.ViewModel(authManager: dc.authManager, authService: dc.authService)
        return LoginView(viewModel: viewModel) {
            path.wrappedValue = [.register]
        }
    }
    
    func makeRegisterView(path: Binding<[AuthCoordinator]>) -> RegisterView {
        let viewModel = RegisterView.ViewModel(authManager: dc.authManager, authService: dc.authService)
        return RegisterView(viewModel: viewModel) {
            path.wrappedValue = []
        }
    }
    
    func makeRootView() -> RootView {
        RootView(authManager: dc.authManager)
    }
    
    func makeSettingsView() -> SettingsView {
        let viewModel = SettingsView.ViewModel(chatService: dc.chatService, authManager: dc.authManager)
        return SettingsView(viewModel: viewModel)
    }
    
    func makeChatView() -> ChatView {
        let viewModel = ChatView.ViewModel(chatService: dc.chatService, authManager: dc.authManager)
        return ChatView(viewModel: viewModel)
    }

    func makeScannerView() -> ScannerView {
        let viewModel = ScannerView.ViewModel(ingredientService: dc.ingredientService, authManager: dc.authManager)
        return ScannerView(viewModel: viewModel)
    }
    
    func makeHomeView() -> HomeView {
        let prayerCardVM = PrayerTimesCardView.ViewModel(
            locationService: dc.locationService,
            prayerTimeService: dc.prayerTimeService,
            settingsStore: dc.prayerSettingsStore
        )
        let viewModel = HomeView.ViewModel(
            verseService: dc.verseService,
            prayerCardViewModel: prayerCardVM,
            authManager: dc.authManager
        )
        return HomeView(viewModel: viewModel)
    }

    func makePrayerNotificationSettingsView() -> PrayerNotificationSettingsView {
        let viewModel = PrayerNotificationSettingsView.ViewModel(
            settingsStore: dc.prayerSettingsStore,
            notificationService: dc.prayerNotificationService,
            locationService: dc.locationService
        )
        return PrayerNotificationSettingsView(viewModel: viewModel)
    }

    func makeQuranListView() -> QuranListView {
        let viewModel = QuranListView.ViewModel(quranStorage: dc.quranStorage)
        return QuranListView(viewModel: viewModel)
    }

    func makeSuraReaderView(suraIndex: Int) -> SuraReaderView {
        let viewModel = SuraReaderView.ViewModel(suraIndex: suraIndex, quranStorage: dc.quranStorage)
        return SuraReaderView(viewModel: viewModel)
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
    }
}
