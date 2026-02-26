//
//  PrayerSettingsStore.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import Foundation
import Observation

private let kPrayerSettingsKey = "HalalAI.prayerSettings"

@Observable
final class PrayerSettingsStore {
    var settings: PrayerSettings {
        didSet { persist() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: kPrayerSettingsKey),
           let decoded = try? JSONDecoder().decode(PrayerSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: kPrayerSettingsKey)
        }
    }
}
