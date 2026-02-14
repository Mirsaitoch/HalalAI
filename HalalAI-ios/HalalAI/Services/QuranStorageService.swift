//
//  QuranStorageService.swift
//  HalalAI
//

import Foundation

protocol QuranStorageService {
    var suras: [Sura] { get }
    var lastReadSuraIndex: Int? { get }
    var lastReadVerseNumber: Int? { get }
    func loadQuranFromBundle() throws
    func saveProgress(suraIndex: Int, verseNumber: Int)
    func clearProgress()
}

private enum UserDefaultsKeys {
    static let lastReadSuraIndex = "quran.lastReadSuraIndex"
    static let lastReadVerseNumber = "quran.lastReadVerseNumber"
}

@Observable
final class QuranStorageServiceImpl: QuranStorageService {
    private(set) var suras: [Sura] = []
    private var surasLoaded = false

    var lastReadSuraIndex: Int? {
        guard UserDefaults.standard.object(forKey: UserDefaultsKeys.lastReadSuraIndex) != nil else { return nil }
        let v = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastReadSuraIndex)
        return v > 0 ? v : nil
    }
    var lastReadVerseNumber: Int? {
        guard UserDefaults.standard.object(forKey: UserDefaultsKeys.lastReadVerseNumber) != nil else { return nil }
        let v = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastReadVerseNumber)
        return v > 0 ? v : nil
    }

    func loadQuranFromBundle() throws {
        if surasLoaded { return }
        guard let url = Bundle.main.url(forResource: "sury", withExtension: "csv") else {
            throw QuranError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw QuranError.encodingError
        }
        suras = try Self.parseCSV(content)
        surasLoaded = true
    }

    func saveProgress(suraIndex: Int, verseNumber: Int) {
        UserDefaults.standard.set(suraIndex, forKey: UserDefaultsKeys.lastReadSuraIndex)
        UserDefaults.standard.set(verseNumber, forKey: UserDefaultsKeys.lastReadVerseNumber)
    }

    func clearProgress() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastReadSuraIndex)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastReadVerseNumber)
    }

    // MARK: - CSV parsing

    private static func parseCSV(_ content: String) throws -> [Sura] {
        let lines = content.components(separatedBy: .newlines)
        guard !lines.isEmpty else { throw QuranError.emptyFile }
        let columnCount = 5
        var currentSuraIndex: Int?
        var currentTitle = ""
        var currentSubtitle = ""
        var currentVerses: [QuranVerse] = []
        var allSuras: [Sura] = []

        for (i, line) in lines.enumerated() {
            if i == 0 && line.hasPrefix("sura_index") { continue }
            let fields = parseCSVLine(line)
            guard fields.count >= columnCount else { continue }
            guard let suraIndex = Int(fields[0]) else { continue }
            let title = fields[1].trimmingCharacters(in: .whitespaces)
            let subtitle = fields[2].trimmingCharacters(in: .whitespaces)
            let verseNumRaw = fields[3].trimmingCharacters(in: .whitespaces)
            let verseNumber = Int(verseNumRaw)
            var text = fields[4].trimmingCharacters(in: .whitespaces)
            if text.hasPrefix("\"") { text.removeFirst() }
            if text.hasSuffix("\"") { text.removeLast() }

            if currentSuraIndex != suraIndex {
                if let idx = currentSuraIndex, !currentVerses.isEmpty {
                    allSuras.append(Sura(
                        id: idx,
                        index: idx,
                        title: currentTitle,
                        subtitle: currentSubtitle,
                        verses: currentVerses
                    ))
                }
                currentSuraIndex = suraIndex
                currentTitle = title
                currentSubtitle = subtitle
                currentVerses = []
            }
            currentVerses.append(QuranVerse(suraIndex: suraIndex, verseNumber: verseNumber, text: text))
        }
        if let idx = currentSuraIndex, !currentVerses.isEmpty {
            allSuras.append(Sura(
                id: idx,
                index: idx,
                title: currentTitle,
                subtitle: currentSubtitle,
                verses: currentVerses
            ))
        }
        return allSuras
    }

    /// Парсит одну строку CSV с учётом кавычек (поля в кавычках могут содержать запятые).
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for ch in line {
            if ch == "\"" {
                inQuotes.toggle()
                continue
            }
            if !inQuotes && ch == "," {
                result.append(current)
                current = ""
                continue
            }
            current.append(ch)
        }
        result.append(current)
        return result
    }
}

enum QuranError: LocalizedError {
    case fileNotFound
    case encodingError
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "Файл Корана не найден в приложении."
        case .encodingError: return "Ошибка кодировки файла."
        case .emptyFile: return "Файл Корана пуст."
        }
    }
}
