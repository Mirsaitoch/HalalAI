//
//  QuranModelsTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct QuranModelsTests {

    // MARK: - QuranVerse

    @Test("QuranVerse id is composed of suraIndex and verseNumber")
    func verseId() {
        let verse = QuranVerse(suraIndex: 2, verseNumber: 255, text: "آية الكرسي")
        #expect(verse.id == "2-255")
    }

    @Test("QuranVerse with nil verseNumber uses 0 in id")
    func verseIdNilNumber() {
        let verse = QuranVerse(suraIndex: 1, verseNumber: nil, text: "بسم الله")
        #expect(verse.id == "1-0")
        #expect(verse.verseNumber == nil)
    }

    @Test("QuranVerse equality")
    func verseEquality() {
        let a = QuranVerse(suraIndex: 1, verseNumber: 1, text: "Text")
        let b = QuranVerse(suraIndex: 1, verseNumber: 1, text: "Text")
        #expect(a == b)
    }

    // MARK: - Sura

    @Test("Sura displayTitle includes index and title")
    func suraDisplayTitle() {
        let sura = Sura(
            id: 1,
            index: 1,
            title: "Аль-Фатиха",
            subtitle: "Открывающая",
            verses: []
        )
        #expect(sura.displayTitle == "1. Аль-Фатиха")
    }

    @Test("Sura with verses preserves verse count")
    func suraVersesCount() {
        let verses = (1...7).map { QuranVerse(suraIndex: 1, verseNumber: $0, text: "Аят \($0)") }
        let sura = Sura(id: 1, index: 1, title: "Аль-Фатиха", subtitle: "Открывающая", verses: verses)
        #expect(sura.verses.count == 7)
    }

    @Test("Sura equality")
    func suraEquality() {
        let a = Sura(id: 1, index: 1, title: "Test", subtitle: "Sub", verses: [])
        let b = Sura(id: 1, index: 1, title: "Test", subtitle: "Sub", verses: [])
        #expect(a == b)
    }
}
