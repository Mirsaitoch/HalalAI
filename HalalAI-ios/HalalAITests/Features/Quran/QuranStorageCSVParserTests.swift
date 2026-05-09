//
//  QuranStorageCSVParserTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct QuranStorageCSVParserTests {

    // MARK: - parseCSV

    @Test("parseCSV parses valid CSV with header and multiple suras")
    func parseValidCSV() throws {
        let csv = """
        sura_index,title,subtitle,verse_number,text
        1,Аль-Фатиха,Открывающая,1,"Во имя Аллаха"
        1,Аль-Фатиха,Открывающая,2,"Хвала Аллаху"
        2,Аль-Бакара,Корова,1,"Алиф Лам Мим"
        """

        let suras = try QuranStorageServiceImpl.parseCSV(csv)

        #expect(suras.count == 2)
        #expect(suras[0].index == 1)
        #expect(suras[0].title == "Аль-Фатиха")
        #expect(suras[0].subtitle == "Открывающая")
        #expect(suras[0].verses.count == 2)
        #expect(suras[1].index == 2)
        #expect(suras[1].title == "Аль-Бакара")
        #expect(suras[1].verses.count == 1)
    }

    @Test("parseCSV returns empty array for empty string")
    func emptyFile() throws {
        let suras = try QuranStorageServiceImpl.parseCSV("")
        #expect(suras.isEmpty)
    }

    @Test("parseCSV returns empty array for header-only CSV")
    func headerOnly() throws {
        let csv = "sura_index,title,subtitle,verse_number,text"
        let suras = try QuranStorageServiceImpl.parseCSV(csv)
        #expect(suras.isEmpty)
    }

    @Test("parseCSV skips rows with fewer than 5 columns")
    func skipShortRows() throws {
        let csv = """
        sura_index,title,subtitle,verse_number,text
        1,Аль-Фатиха,Открывающая,1,"Во имя Аллаха"
        short,row
        1,Аль-Фатиха,Открывающая,2,"Хвала Аллаху"
        """

        let suras = try QuranStorageServiceImpl.parseCSV(csv)
        #expect(suras.count == 1)
        #expect(suras[0].verses.count == 2)
    }

    @Test("parseCSV skips rows with non-numeric sura_index")
    func skipInvalidSuraIndex() throws {
        let csv = """
        sura_index,title,subtitle,verse_number,text
        abc,Bad,Sura,1,Text
        1,Good,Sura,1,Text
        """

        let suras = try QuranStorageServiceImpl.parseCSV(csv)
        #expect(suras.count == 1)
        #expect(suras[0].title == "Good")
    }

    @Test("parseCSV handles verse with nil verseNumber")
    func nilVerseNumber() throws {
        let csv = """
        sura_index,title,subtitle,verse_number,text
        1,Аль-Фатиха,Открывающая,,Бисмиллях
        1,Аль-Фатиха,Открывающая,1,Во имя Аллаха
        """

        let suras = try QuranStorageServiceImpl.parseCSV(csv)
        #expect(suras.count == 1)
        #expect(suras[0].verses.count == 2)
        #expect(suras[0].verses[0].verseNumber == nil)
        #expect(suras[0].verses[1].verseNumber == 1)
    }

    @Test("parseCSV strips quotes from verse text")
    func stripsQuotes() throws {
        let csv = """
        sura_index,title,subtitle,verse_number,text
        1,Test,Sub,1,"Quoted text"
        """

        let suras = try QuranStorageServiceImpl.parseCSV(csv)
        let verse = try #require(suras.first?.verses.first)
        #expect(verse.text == "Quoted text")
    }

    @Test("parseCSV groups consecutive verses into same sura")
    func groupsVerses() throws {
        let csv = """
        sura_index,title,subtitle,verse_number,text
        3,Аль-Имран,Семейство Имрана,1,Алиф
        3,Аль-Имран,Семейство Имрана,2,Лам
        3,Аль-Имран,Семейство Имрана,3,Мим
        """

        let suras = try QuranStorageServiceImpl.parseCSV(csv)
        #expect(suras.count == 1)
        #expect(suras[0].verses.count == 3)
    }

    // MARK: - parseCSVLine

    @Test("parseCSVLine splits simple comma-separated fields")
    func simpleFields() {
        let result = QuranStorageServiceImpl.parseCSVLine("a,b,c,d,e")
        #expect(result == ["a", "b", "c", "d", "e"])
    }

    @Test("parseCSVLine handles quoted fields with commas")
    func quotedWithCommas() {
        let result = QuranStorageServiceImpl.parseCSVLine("1,Title,Sub,1,\"Hello, world\"")
        #expect(result.count == 5)
        #expect(result[4] == "Hello, world")
    }

    @Test("parseCSVLine handles empty fields")
    func emptyFields() {
        let result = QuranStorageServiceImpl.parseCSVLine("1,Title,Sub,,")
        #expect(result.count == 5)
        #expect(result[3] == "")
        #expect(result[4] == "")
    }

    @Test("parseCSVLine handles empty string")
    func emptyString() {
        let result = QuranStorageServiceImpl.parseCSVLine("")
        #expect(result == [""])
    }
}
