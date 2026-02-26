//
//  PrayerModels.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import Foundation

// MARK: - Prayer

enum Prayer: String, CaseIterable, Codable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha
    
    var localizedName: String {
        switch self {
        case .fajr:
            return "Фаджр"
        case .sunrise:
            return "Шурук"
        case .dhuhr:
            return "Зухр"
        case .asr:
            return "Аср"
        case .maghrib:
            return "Магриб"
        case .isha:
            return "Иша"
        }
    }
    
    var systemImage: String {
        switch self {
        case .fajr:
            return "moon.stars"
        case .sunrise:
            return "sunrise"
        case .dhuhr:
            return "sun.max"
        case .asr:
            return "sun.min"
        case .maghrib:
            return "sunset"
        case .isha:
            return "moon"
        }
    }
    
    static var notifiablePrayers: [Prayer] {
        [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }
}

// MARK: - DailyPrayerTimes

struct DailyPrayerTimes {
    let date: Date
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    
    func time(for prayer: Prayer) -> Date {
        switch prayer {
        case .fajr:
            return fajr
        case .sunrise:
            return sunrise
        case .dhuhr:
            return dhuhr
        case .asr:
            return asr
        case .maghrib:
            return maghrib
        case .isha:
            return isha
        }
    }
    
    var allPrayers: [(Prayer, Date)] {
        Prayer.allCases.map { ($0, time(for: $0)) }
    }
}

// MARK: - Calculation Method

enum PrayerCalculationMethod: String, CaseIterable, Codable {
    case russia = "russia"
    case tatarstan = "tatarstan"
    case muslimWorldLeague = "mwl"
    case isna = "isna"
    case egypt = "egypt"
    case makkah = "makkah"
    case karachi = "karachi"
    case tehran = "tehran"

    
    var localizedName: String {
        switch self {
        case .russia:
            return "ДУМ России"
        case .tatarstan:
            return "ДУМ Республики Татарстан"
        case .muslimWorldLeague:
            return "Мировая Исламская Лига"
        case .isna:
            return "ISNA (Северная Америка)"
        case .egypt:
            return "Египетский"
        case .makkah:
            return "Умм аль-Кура (Мекка)"
        case .karachi:
            return "Карачи"
        case .tehran:
            return "Тегеран"
        }
    }
    
    var fajrAngle: Double {
        switch self {
        case .muslimWorldLeague:
            return 18.0
        case .isna:
            return 15.0
        case .egypt:
            return 19.5
        case .makkah:
            return 18.5
        case .karachi:
            return 18.0
        case .tehran:
            return 17.7
        case .russia:
            return 16.0
        case .tatarstan:
            return 18.0
        }
    }
    
    var ishaAngle: Double {
        switch self {
        case .muslimWorldLeague:
            return 17.0
        case .isna:
            return 15.0
        case .egypt:
            return 17.5
        case .makkah:
            return 90.0 / 60  // ~1.5°
        case .karachi:
            return 18.0
        case .tehran:
            return 14.0
        case .russia:
            return 15.0
        case .tatarstan:
            return 15.0
        }
    }
}

// MARK: - Madhab

enum Madhab: String, CaseIterable, Codable {
    case shafi = "shafi"
    case hanafi = "hanafi"
    
    var localizedName: String {
        switch self {
        case .shafi:
            return "Шафии / Маликии / Ханбали"
        case .hanafi:
            return "Ханафи"
        }
    }
    
    var asrShadowFactor: Double {
        switch self {
        case .shafi:
            return 1.0
        case .hanafi:
            return 2.0
        }
    }
}

// MARK: - Notification Settings

struct PrayerNotificationSetting: Codable, Equatable {
    var isEnabled: Bool
    var offsetMinutes: Int
    
    static let `default` = PrayerNotificationSetting(isEnabled: false, offsetMinutes: 0)
}

// MARK: - Prayer Settings

struct PrayerSettings: Codable {
    var calculationMethod: PrayerCalculationMethod
    var madhab: Madhab
    var customFajrAngle: Double?
    var customIshaAngle: Double?
    var notifications: [String: PrayerNotificationSetting]
    
    static let `default` = PrayerSettings(
        calculationMethod: .muslimWorldLeague,
        madhab: .shafi,
        customFajrAngle: nil,
        customIshaAngle: nil,
        notifications: Prayer.notifiablePrayers.reduce(into: [:]) { dict, prayer in
            dict[prayer.rawValue] = .default
        }
    )
    
    func notificationSetting(for prayer: Prayer) -> PrayerNotificationSetting {
        notifications[prayer.rawValue] ?? .default
    }
    
    mutating func setNotification(_ setting: PrayerNotificationSetting, for prayer: Prayer) {
        notifications[prayer.rawValue] = setting
    }
}
