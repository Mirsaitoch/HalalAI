//
//  SuraReaderViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 14.02.2026.
//

import SwiftUI

extension SuraReaderView {
    @Observable
    final class ViewModel {
        var suraIndex: Int
        var quranStorage: QuranStorageService
        var sura: Sura?
        var fontSize: CGFloat = 18
        var lastTrackedSura: Int?
        var lastTrackedVerse: Int?
        
        init(suraIndex: Int, quranStorage: QuranStorageService) {
            self.suraIndex = suraIndex
            self.quranStorage = quranStorage
        }
        
        func trackVisibleVerse(suraIndex: Int, verseNumber: Int) {
            lastTrackedSura = suraIndex
            lastTrackedVerse = verseNumber
        }

        func saveProgressIfNeeded() {
            if let s = lastTrackedSura, let v = lastTrackedVerse {
                quranStorage.saveProgress(suraIndex: s, verseNumber: v)
            }
        }

        func loadSura() {
            if !quranStorage.suras.isEmpty {
                sura = quranStorage.suras.first { $0.index == suraIndex }
                return
            }
            Task {
                try? quranStorage.loadQuranFromBundle()
                await MainActor.run {
                    sura = quranStorage.suras.first { $0.index == suraIndex }
                }
            }
        }
    }
}
