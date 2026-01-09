//
//  Verse.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 09.01.2026.
//

import Foundation

struct Verse: Codable, Equatable, Hashable {
    let id: Int
    let suraIndex: Int
    let suraTitle: String
    let suraSubtitle: String
    let verseNumber: Int
    let text: String
}
