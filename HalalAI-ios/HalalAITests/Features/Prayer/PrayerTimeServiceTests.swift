//
//  PrayerTimeServiceTests.swift
//  HalalAITests
//

import Foundation
import Testing
import CoreLocation
@testable import HalalAI

struct PrayerTimeServiceTests {
    let sut = PrayerTimeServiceImpl()

    // MARK: - Known Location (Moscow)

    private static let moscowLocation = CLLocation(latitude: 55.7558, longitude: 37.6173)

    @Test("Calculates prayer times for a known date and location")
    func calculateTimesForMoscow() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 21))!

        let times = sut.calculateTimes(
            for: date,
            location: Self.moscowLocation,
            settings: .default
        )

        let result = try #require(times)
        #expect(result.fajr < result.sunrise, "Fajr must be before sunrise")
        #expect(result.sunrise < result.dhuhr, "Sunrise must be before dhuhr")
        #expect(result.dhuhr < result.asr, "Dhuhr must be before asr")
        #expect(result.asr < result.maghrib, "Asr must be before maghrib")
        #expect(result.maghrib < result.isha, "Maghrib must be before isha")
    }

    @Test("Different calculation methods produce different times",
          arguments: [
            PrayerCalculationMethod.muslimWorldLeague,
            .russia,
            .makkah
          ])
    func differentMethodsDifferentTimes(method: PrayerCalculationMethod) {
        let date = Date(timeIntervalSince1970: 1_711_000_000)

        var settings = PrayerSettings.default
        settings.calculationMethod = method

        let times = sut.calculateTimes(
            for: date,
            location: Self.moscowLocation,
            settings: settings
        )

        #expect(times != nil, "\(method) should produce valid times")
    }

    @Test("Custom angles are accepted without crashing")
    func customAnglesAccepted() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 21))!

        var settings = PrayerSettings.default
        settings.customFajrAngle = 10.0
        settings.customIshaAngle = 12.0

        let times = sut.calculateTimes(
            for: date, location: Self.moscowLocation, settings: settings
        )

        #expect(times != nil, "Custom angles should still produce valid times")
    }

    @Test("Hanafi madhab produces later asr time than Shafi")
    func hanafiAsrLater() throws {
        let date = Date(timeIntervalSince1970: 1_711_000_000)

        var shafiSettings = PrayerSettings.default
        shafiSettings.madhab = .shafi
        let shafiTimes = sut.calculateTimes(
            for: date, location: Self.moscowLocation, settings: shafiSettings
        )

        var hanafiSettings = PrayerSettings.default
        hanafiSettings.madhab = .hanafi
        let hanafiTimes = sut.calculateTimes(
            for: date, location: Self.moscowLocation, settings: hanafiSettings
        )

        let shafiAsr = try #require(shafiTimes?.asr)
        let hanafiAsr = try #require(hanafiTimes?.asr)

        #expect(hanafiAsr > shafiAsr, "Hanafi asr should be later than Shafi")
    }

    // MARK: - nextPrayer

    @Test("nextPrayer returns first prayer after current time")
    func nextPrayerFindsCorrectOne() throws {
        let now = Date()
        let times = DailyPrayerTimes(
            date: now,
            fajr: now.addingTimeInterval(-7200),
            sunrise: now.addingTimeInterval(-3600),
            dhuhr: now.addingTimeInterval(1800),
            asr: now.addingTimeInterval(7200),
            maghrib: now.addingTimeInterval(14400),
            isha: now.addingTimeInterval(21600)
        )

        let next = sut.nextPrayer(from: times)
        let (prayer, _) = try #require(next)
        #expect(prayer == .dhuhr)
    }

    @Test("nextPrayer returns nil when all prayers have passed")
    func nextPrayerNilWhenAllPassed() {
        let now = Date()
        let times = DailyPrayerTimes(
            date: now,
            fajr: now.addingTimeInterval(-21600),
            sunrise: now.addingTimeInterval(-18000),
            dhuhr: now.addingTimeInterval(-14400),
            asr: now.addingTimeInterval(-10800),
            maghrib: now.addingTimeInterval(-7200),
            isha: now.addingTimeInterval(-3600)
        )

        let next = sut.nextPrayer(from: times)
        #expect(next == nil)
    }
}
