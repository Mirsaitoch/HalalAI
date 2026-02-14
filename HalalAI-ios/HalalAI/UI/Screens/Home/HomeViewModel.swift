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
        init(verseService: VerseService) {
            self.verseService = verseService
        }
    }
}
