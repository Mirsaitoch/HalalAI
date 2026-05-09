//
//  SuraReaderViewModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct SuraReaderViewModelTests {

    @Test("trackVisibleVerse stores sura and verse")
    func trackVisibleVerse() {
        let (vm, _) = makeSUT(suraIndex: 2)

        vm.trackVisibleVerse(suraIndex: 2, verseNumber: 255)

        #expect(vm.lastTrackedSura == 2)
        #expect(vm.lastTrackedVerse == 255)
    }

    @Test("saveProgressIfNeeded saves when tracking data exists")
    func saveProgressWithData() {
        let (vm, storage) = makeSUT(suraIndex: 1)
        vm.trackVisibleVerse(suraIndex: 1, verseNumber: 5)

        vm.saveProgressIfNeeded()

        #expect(storage.saveProgressCallCount == 1)
        #expect(storage.savedSuraIndex == 1)
        #expect(storage.savedVerseNumber == 5)
    }

    @Test("saveProgressIfNeeded does nothing without tracking data")
    func saveProgressWithoutData() {
        let (vm, storage) = makeSUT(suraIndex: 1)

        vm.saveProgressIfNeeded()

        #expect(storage.saveProgressCallCount == 0)
    }

    @Test("loadSura finds sura from pre-loaded storage")
    func loadSuraFromPreloaded() {
        let (vm, storage) = makeSUT(suraIndex: 2)
        storage.suras = [
            Sura(id: 1, index: 1, title: "Аль-Фатиха", subtitle: "Открывающая", verses: []),
            Sura(id: 2, index: 2, title: "Аль-Бакара", subtitle: "Корова", verses: [])
        ]

        vm.loadSura()

        #expect(vm.sura?.index == 2)
        #expect(vm.sura?.title == "Аль-Бакара")
    }

    @Test("loadSura returns nil for non-existent sura index")
    func loadSuraNonExistent() {
        let (vm, storage) = makeSUT(suraIndex: 999)
        storage.suras = [
            Sura(id: 1, index: 1, title: "Test", subtitle: "Sub", verses: [])
        ]

        vm.loadSura()

        #expect(vm.sura == nil)
    }

    @Test("Initial fontSize is 18")
    func defaultFontSize() {
        let (vm, _) = makeSUT(suraIndex: 1)
        #expect(vm.fontSize == 18)
    }

    // MARK: - Helpers

    private func makeSUT(suraIndex: Int) -> (SuraReaderView.ViewModel, MockQuranStorageService) {
        let storage = MockQuranStorageService()
        let vm = SuraReaderView.ViewModel(suraIndex: suraIndex, quranStorage: storage)
        return (vm, storage)
    }
}
