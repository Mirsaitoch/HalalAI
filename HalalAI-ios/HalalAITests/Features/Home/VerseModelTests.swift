//
//  VerseModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct VerseModelTests {

    @Test("Verse encodes and decodes correctly")
    func verseCodable() throws {
        let verse = Verse(
            id: 42,
            suraIndex: 2,
            suraTitle: "Аль-Бакара",
            suraSubtitle: "Корова",
            verseNumber: 255,
            text: "Аллах — нет божества, кроме Него"
        )

        let data = try JSONEncoder().encode(verse)
        let decoded = try JSONDecoder().decode(Verse.self, from: data)

        #expect(decoded == verse)
        #expect(decoded.id == 42)
        #expect(decoded.suraIndex == 2)
        #expect(decoded.suraTitle == "Аль-Бакара")
        #expect(decoded.suraSubtitle == "Корова")
        #expect(decoded.verseNumber == 255)
        #expect(decoded.text == "Аллах — нет божества, кроме Него")
    }

    @Test("Verse equality works correctly")
    func verseEquality() {
        let a = Verse(id: 1, suraIndex: 1, suraTitle: "T", suraSubtitle: "S", verseNumber: 1, text: "X")
        let b = Verse(id: 1, suraIndex: 1, suraTitle: "T", suraSubtitle: "S", verseNumber: 1, text: "X")
        let c = Verse(id: 2, suraIndex: 1, suraTitle: "T", suraSubtitle: "S", verseNumber: 1, text: "X")

        #expect(a == b)
        #expect(a != c)
    }

    @Test("Verse is Hashable")
    func verseHashable() {
        let verse = Verse(id: 1, suraIndex: 1, suraTitle: "T", suraSubtitle: "S", verseNumber: 1, text: "X")
        let set: Set<Verse> = [verse, verse]

        #expect(set.count == 1)
    }

    @Test("Verse decodes from JSON")
    func verseDecodeFromJSON() throws {
        let json = """
        {
            "id": 10,
            "suraIndex": 3,
            "suraTitle": "Аль-Имран",
            "suraSubtitle": "Семейство Имрана",
            "verseNumber": 18,
            "text": "Свидетельствует Аллах"
        }
        """.data(using: .utf8)!

        let verse = try JSONDecoder().decode(Verse.self, from: json)
        #expect(verse.id == 10)
        #expect(verse.suraIndex == 3)
        #expect(verse.verseNumber == 18)
    }
}
