//
//  AppLanguage.swift
//  HalalAI
//

import Foundation

enum AppLanguage: String, CaseIterable, Codable {
    case russian = "ru"
    case english = "en"

    var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .russian: return Locale(identifier: "ru_RU")
        case .english: return Locale(identifier: "en_US")
        }
    }
}
