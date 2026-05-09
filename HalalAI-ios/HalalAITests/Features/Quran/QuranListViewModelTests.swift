//
//  QuranListViewModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct QuranListViewModelTests {

    @Test("Initial state has isLoading true and no suras")
    func initialState() {
        let (vm, _) = makeSUT()

        #expect(vm.isLoading == true)
        #expect(vm.suras.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadQuran loads suras from storage")
    func loadQuranSuccess() async throws {
        let (vm, storage) = makeSUT()
        storage.suras = [
            Sura(id: 1, index: 1, title: "Аль-Фатиха", subtitle: "Открывающая", verses: []),
            Sura(id: 2, index: 2, title: "Аль-Бакара", subtitle: "Корова", verses: [])
        ]

        vm.loadQuran()
        try await Task.sleep(for: .milliseconds(50))

        #expect(vm.suras.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(storage.loadCallCount == 1)
    }

    @Test("loadQuran sets errorMessage on failure")
    func loadQuranFailure() async throws {
        let (vm, storage) = makeSUT()
        storage.shouldThrow = true

        vm.loadQuran()
        try await Task.sleep(for: .milliseconds(50))

        #expect(vm.isLoading == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Helpers

    private func makeSUT() -> (QuranListView.ViewModel, MockQuranStorageService) {
        let storage = MockQuranStorageService()
        let vm = QuranListView.ViewModel(quranStorage: storage)
        return (vm, storage)
    }
}
