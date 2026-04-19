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

        init(
            verseService: VerseService,
            prayerCardViewModel: PrayerTimesCardView.ViewModel,
            authManager: AuthManager
        ) {
            self.verseService = verseService
            self.prayerCardViewModel = prayerCardViewModel
            self.authManager = authManager
        }
        
        deinit {
            print("deinit HomeViewModel")
        }
    }
}
