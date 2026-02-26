//
//  PrayerNotificationService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import Foundation
import UserNotifications
import CoreLocation

protocol PrayerNotificationService: AnyObject {
    func requestAuthorization() async -> Bool
    func scheduleNotifications(settings: PrayerSettings, location: CLLocation) async
    func cancelAllPrayerNotifications() async
    func sendTestNotification() async
}

final class PrayerNotificationServiceImpl: PrayerNotificationService {

    private let prayerTimeService: PrayerTimeService
    private let center = UNUserNotificationCenter.current()

    init(prayerTimeService: PrayerTimeService) {
        self.prayerTimeService = prayerTimeService
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification auth error: \(error)")
            return false
        }
    }

    // MARK: - Scheduling

    /// Schedules prayer notifications for the next 7 days (max 35 notifications).
    func scheduleNotifications(settings: PrayerSettings, location: CLLocation) async {
        await cancelAllPrayerNotifications()

        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            guard let times = prayerTimeService.calculateTimes(
                for: targetDate,
                location: location,
                settings: settings
            ) else { continue }

            for prayer in Prayer.notifiablePrayers {
                let notifSetting = settings.notificationSetting(for: prayer)
                guard notifSetting.isEnabled else { continue }

                let prayerDate = times.time(for: prayer)
                let fireDate = prayerDate.addingTimeInterval(-Double(notifSetting.offsetMinutes) * 60)

                guard fireDate > Date() else { continue }

                let identifier = "prayer_\(prayer.rawValue)_\(dayOffset)"
                await schedule(
                    identifier: identifier,
                    prayer: prayer,
                    offsetMinutes: notifSetting.offsetMinutes,
                    fireDate: fireDate
                )
            }
        }
    }

    func cancelAllPrayerNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let prayerIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("prayer_") }
        center.removePendingNotificationRequests(withIdentifiers: prayerIDs)
    }

    // MARK: - Test

    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Тест уведомления"
        content.body = "Уведомления о намазе работают!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "prayer_test", content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Test notification error: \(error)")
        }
    }

    // MARK: - Private

    private func schedule(
        identifier: String,
        prayer: Prayer,
        offsetMinutes: Int,
        fireDate: Date
    ) async {
        let content = UNMutableNotificationContent()

        if offsetMinutes == 0 {
            content.title = "Время намаза: \(prayer.localizedName)"
            content.body = "Наступило время \(prayer.localizedName)"
        } else {
            content.title = "\(prayer.localizedName) через \(offsetMinutes) мин"
            content.body = "Подготовьтесь к намазу \(prayer.localizedName)"
        }
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Schedule notification error (\(identifier)): \(error)")
        }
    }
}
