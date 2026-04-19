//
//  QuranModels.swift
//  HalalAI
//

import Foundation

struct QuranVerse: Identifiable, Equatable {
    let id: String
    /// Номер аята (может быть пустым для Бисмилля)
    let verseNumber: Int?
    let text: String

    init(suraIndex: Int, verseNumber: Int?, text: String) {
        self.id = "\(suraIndex)-\(verseNumber ?? 0)"
        self.verseNumber = verseNumber
        self.text = text
    }
}

struct Sura: Identifiable, Equatable {
    let id: Int
    let index: Int
    let title: String
    let subtitle: String
    let verses: [QuranVerse]

    var displayTitle: String { "\(index). \(title)" }
}
