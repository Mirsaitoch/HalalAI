//
//  PrayerModelsTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct PrayerModelsTests {

    // MARK: - Prayer Enum

    @Test("Prayer has 6 cases")
    func prayerCaseCount() {
        #expect(Prayer.allCases.count == 6)
    }

    @Test("Notifiable prayers exclude sunrise",
          arguments: Prayer.notifiablePrayers)
    func notifiablePrayersExcludeSunrise(prayer: Prayer) {
        #expect(prayer != .sunrise)
    }

    @Test("Sunrise is not in notifiable prayers")
    func sunriseNotNotifiable() {
        #expect(Prayer.notifiablePrayers.contains(.sunrise) == false)
    }

    @Test("Localized prayer names are in Russian",
          arguments: [
            (Prayer.fajr, "Фаджр"),
            (Prayer.sunrise, "Шурук"),
            (Prayer.dhuhr, "Зухр"),
            (Prayer.asr, "Аср"),
            (Prayer.maghrib, "Магриб"),
            (Prayer.isha, "Иша")
          ])
    func localizedNames(prayer: Prayer, expected: String) {
        #expect(prayer.localizedName == expected)
    }

    @Test("Each prayer has a system image",
          arguments: Prayer.allCases)
    func systemImages(prayer: Prayer) {
        #expect(prayer.systemImage.isEmpty == false)
    }

    // MARK: - DailyPrayerTimes

    @Test("time(for:) returns correct date for each prayer")
    func timeForPrayer() {
        let now = Date()
        let times = makeDailyTimes(base: now)

        for prayer in Prayer.allCases {
            let time = times.time(for: prayer)
            let expectedOffset = Double(Prayer.allCases.firstIndex(of: prayer)!) * 3600
            let expected = now.addingTimeInterval(expectedOffset)
            #expect(time == expected, "time(for: \(prayer)) should match")
        }
    }

    @Test("allPrayers returns all 6 entries in order")
    func allPrayersCount() {
        let times = makeDailyTimes(base: Date())
        #expect(times.allPrayers.count == 6)
        #expect(times.allPrayers.map(\.0) == Prayer.allCases)
    }

    // MARK: - PrayerCalculationMethod

    @Test("All calculation methods have localized names",
          arguments: PrayerCalculationMethod.allCases)
    func calculationMethodNames(method: PrayerCalculationMethod) {
        #expect(method.localizedName.isEmpty == false)
    }

    @Test("Fajr angle is positive for all methods",
          arguments: PrayerCalculationMethod.allCases)
    func fajrAnglePositive(method: PrayerCalculationMethod) {
        #expect(method.fajrAngle > 0)
    }

    @Test("Isha angle is positive for all methods",
          arguments: PrayerCalculationMethod.allCases)
    func ishaAnglePositive(method: PrayerCalculationMethod) {
        #expect(method.ishaAngle > 0)
    }

    // MARK: - Madhab

    @Test("Madhab shadow factors",
          arguments: [
            (Madhab.shafi, 1.0),
            (Madhab.hanafi, 2.0)
          ])
    func madhabShadowFactor(madhab: Madhab, expected: Double) {
        #expect(madhab.asrShadowFactor == expected)
    }

    // MARK: - PrayerSettings

    @Test("Default settings use Muslim World League and Shafi")
    func defaultSettings() {
        let settings = PrayerSettings.default
        #expect(settings.calculationMethod == .muslimWorldLeague)
        #expect(settings.madhab == .shafi)
        #expect(settings.customFajrAngle == nil)
        #expect(settings.customIshaAngle == nil)
    }

    @Test("Default notifications are disabled for all notifiable prayers")
    func defaultNotificationsDisabled() {
        let settings = PrayerSettings.default
        for prayer in Prayer.notifiablePrayers {
            let notification = settings.notificationSetting(for: prayer)
            #expect(notification.isEnabled == false, "\(prayer) notification should be disabled by default")
            #expect(notification.offsetMinutes == 0)
        }
    }

    @Test("setNotification updates notification for specific prayer")
    func setNotification() {
        var settings = PrayerSettings.default
        let custom = PrayerNotificationSetting(isEnabled: true, offsetMinutes: 15)
        settings.setNotification(custom, for: .fajr)

        let fajrSetting = settings.notificationSetting(for: .fajr)
        #expect(fajrSetting.isEnabled == true)
        #expect(fajrSetting.offsetMinutes == 15)

        let dhuhrSetting = settings.notificationSetting(for: .dhuhr)
        #expect(dhuhrSetting.isEnabled == false, "Other prayers should remain unchanged")
    }

    @Test("PrayerSettings encodes and decodes correctly")
    func settingsCodable() throws {
        var original = PrayerSettings.default
        original.calculationMethod = .russia
        original.madhab = .hanafi
        original.customFajrAngle = 16.5

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PrayerSettings.self, from: data)

        #expect(decoded.calculationMethod == .russia)
        #expect(decoded.madhab == .hanafi)
        #expect(decoded.customFajrAngle == 16.5)
        #expect(decoded.customIshaAngle == nil)
    }

    // MARK: - PrayerNotificationSetting

    @Test("Default notification setting values")
    func defaultNotificationSetting() {
        let setting = PrayerNotificationSetting.default
        #expect(setting.isEnabled == false)
        #expect(setting.offsetMinutes == 0)
    }

    @Test("PrayerNotificationSetting equality")
    func notificationSettingEquality() {
        let a = PrayerNotificationSetting(isEnabled: true, offsetMinutes: 10)
        let b = PrayerNotificationSetting(isEnabled: true, offsetMinutes: 10)
        let c = PrayerNotificationSetting(isEnabled: false, offsetMinutes: 10)
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Helpers

    private func makeDailyTimes(base: Date) -> DailyPrayerTimes {
        DailyPrayerTimes(
            date: base,
            fajr: base,
            sunrise: base.addingTimeInterval(3600),
            dhuhr: base.addingTimeInterval(7200),
            asr: base.addingTimeInterval(10800),
            maghrib: base.addingTimeInterval(14400),
            isha: base.addingTimeInterval(18000)
        )
    }
}
