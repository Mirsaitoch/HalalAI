//
//  QuranListViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 14.02.2026.
//

import Foundation

extension QuranListView {
    @Observable
    final class ViewModel {
        var quranStorage: QuranStorageService
        var suras: [Sura] = []
        var isLoading = true
        var errorMessage: String?
        
        init(quranStorage: QuranStorageService) {
            self.quranStorage = quranStorage
        }
        
        func loadQuran() {
            isLoading = true
            errorMessage = nil
            Task {
                do {
                    try quranStorage.loadQuranFromBundle()
                    await MainActor.run {
                        suras = quranStorage.suras
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            }
        }

    }
}
