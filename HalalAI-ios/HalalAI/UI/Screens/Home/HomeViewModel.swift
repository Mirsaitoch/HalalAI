//
//  HomeViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 14.02.2026.
//

import Foundation

extension HomeView {
    @Observable
    final class ViewModel {
        var verseService: VerseService
        var prayerCardViewModel: PrayerTimesCardView.ViewModel

        init(
            verseService: VerseService,
            prayerCardViewModel: PrayerTimesCardView.ViewModel
        ) {
            self.verseService = verseService
            self.prayerCardViewModel = prayerCardViewModel
        }
    }
}
