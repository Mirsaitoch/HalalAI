//
//  PrayerTimesCardViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 01.04.2026.
//

import Foundation

extension PrayerTimesCardView {
    @Observable
    @MainActor
    final class ViewModel {
        let locationService: LocationService
        private let prayerTimeService: PrayerTimeService
        private let settingsStore: PrayerSettingsStore

        private let calendar = Calendar(identifier: .gregorian)
        private var cachedStartOfToday: Date?
        /// Если `nil`, используется умный режим: сегодня, пока есть ожидающий намаз; иначе завтра.
        private var preferredDayOffset: Int?

        private(set) var todayTimes: DailyPrayerTimes?
        var displayedTimes: DailyPrayerTimes?
        var nextPrayer: (Prayer, Date)?

        private let minDayOffset = -7
        private let maxDayOffset = 30

        var effectiveDayOffset: Int {
            guard let today = todayTimes else { return 0 }
            let smart = prayerTimeService.nextPrayer(from: today) != nil ? 0 : 1
            return preferredDayOffset ?? smart
        }

        var displayedDayTitle: String {
            let offset = effectiveDayOffset
            let start = calendar.startOfDay(for: Date())
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return "" }
            switch offset {
            case 0:
                return "Сегодня"
            case 1:
                return "Завтра"
            case -1:
                return "Вчера"
            default:
                let f = DateFormatter()
                f.locale = Locale(identifier: "ru_RU")
                f.dateFormat = "d MMMM, EEEE"
                return f.string(from: day).capitalized
            }
        }

        var canShiftToPreviousDay: Bool { effectiveDayOffset > minDayOffset }
        var canShiftToNextDay: Bool { effectiveDayOffset < maxDayOffset }

        init(
            locationService: LocationService,
            prayerTimeService: PrayerTimeService,
            settingsStore: PrayerSettingsStore
        ) {
            self.locationService = locationService
            self.prayerTimeService = prayerTimeService
            self.settingsStore = settingsStore
        }

        func refresh() {
            locationService.requestLocation()
            recalculate()
        }

        func shiftDisplayedDay(by delta: Int) {
            if todayTimes == nil {
                recalculate()
            }
            guard let today = todayTimes else { return }
            let smart = prayerTimeService.nextPrayer(from: today) != nil ? 0 : 1
            let current = preferredDayOffset ?? smart
            preferredDayOffset = min(maxDayOffset, max(minDayOffset, current + delta))
            recalculate()
        }

        func isNextPrayerRow(prayer: Prayer, time: Date) -> Bool {
            guard let (p, when) = nextPrayer else { return false }
            guard p == prayer else { return false }
            return calendar.isDate(when, equalTo: time, toGranularity: .minute)
        }

        func recalculate() {
            guard let loc = locationService.currentLocation else { return }
            let settings = settingsStore.settings
            let startOfToday = calendar.startOfDay(for: Date())
            if cachedStartOfToday != startOfToday {
                cachedStartOfToday = startOfToday
                preferredDayOffset = nil
            }

            todayTimes = prayerTimeService.calculateTimes(
                for: startOfToday,
                location: loc,
                settings: settings
            )

            guard let today = todayTimes else {
                displayedTimes = nil
                nextPrayer = nil
                return
            }

            if let next = prayerTimeService.nextPrayer(from: today) {
                nextPrayer = next
            } else if let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfToday),
                      let tomorrowTimes = prayerTimeService.calculateTimes(
                        for: tomorrowStart,
                        location: loc,
                        settings: settings
                      ) {
                nextPrayer = prayerTimeService.nextPrayer(from: tomorrowTimes) ?? (.fajr, tomorrowTimes.fajr)
            } else {
                nextPrayer = nil
            }

            let smartOffset = prayerTimeService.nextPrayer(from: today) != nil ? 0 : 1
            let offset = preferredDayOffset ?? smartOffset
            let clamped = min(maxDayOffset, max(minDayOffset, offset))
            guard let displayStart = calendar.date(byAdding: .day, value: clamped, to: startOfToday) else {
                displayedTimes = nil
                return
            }
            displayedTimes = prayerTimeService.calculateTimes(
                for: displayStart,
                location: loc,
                settings: settings
            )
        }
    }
}
