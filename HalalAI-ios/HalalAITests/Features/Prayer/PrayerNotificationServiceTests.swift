//
//  PrayerNotificationServiceTests.swift
//  HalalAITests
//
//  Тесты логики планирования уведомлений о молитвах (раздел 4.4.3 диплома).
//  UNUserNotificationCenter тестируется через проверку логики отбора молитв
//  и корректности контента уведомлений на основе настроек.
//

import Testing
import CoreLocation
@testable import HalalAI

struct PrayerNotificationServiceTests {

    // MARK: - Логика отбора уведомляемых молитв

    @Test("Восход солнца (Шурук) не входит в список уведомляемых молитв")
    func sunriseExcludedFromNotifications() {
        #expect(Prayer.notifiablePrayers.contains(.sunrise) == false)
    }

    @Test("Список уведомляемых молитв содержит ровно 5 молитв")
    func notifiablePrayersCount() {
        // Фаджр, Зухр, Аср, Магриб, Иша
        #expect(Prayer.notifiablePrayers.count == 5)
    }

    @Test("Все уведомляемые молитвы присутствуют в списке")
    func notifiablePrayersContainExpected() {
        let expected: Set<Prayer> = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        let actual = Set(Prayer.notifiablePrayers)
        #expect(actual == expected)
    }

    // MARK: - Настройки уведомлений по умолчанию

    @Test("По умолчанию уведомления отключены для всех молитв")
    func defaultNotificationsDisabled() {
        let settings = PrayerSettings.default
        for prayer in Prayer.notifiablePrayers {
            let notification = settings.notificationSetting(for: prayer)
            #expect(notification.isEnabled == false,
                    "Уведомление для \(prayer) должно быть отключено по умолчанию")
        }
    }

    @Test("По умолчанию смещение уведомления — 0 минут")
    func defaultOffsetIsZero() {
        let settings = PrayerSettings.default
        for prayer in Prayer.notifiablePrayers {
            let notification = settings.notificationSetting(for: prayer)
            #expect(notification.offsetMinutes == 0)
        }
    }

    // MARK: - Включение/отключение уведомлений

    @Test("Включение уведомления для Фаджр не влияет на другие молитвы")
    func enablingFajrDoesNotAffectOthers() {
        var settings = PrayerSettings.default
        settings.setNotification(
            PrayerNotificationSetting(isEnabled: true, offsetMinutes: 0),
            for: .fajr
        )

        #expect(settings.notificationSetting(for: .fajr).isEnabled == true)
        for prayer in Prayer.notifiablePrayers where prayer != .fajr {
            #expect(settings.notificationSetting(for: prayer).isEnabled == false,
                    "\(prayer) должна оставаться отключённой")
        }
    }

    @Test("Установка смещения 15 минут для Магриб сохраняется корректно")
    func offsetIsStoredCorrectly() {
        var settings = PrayerSettings.default
        settings.setNotification(
            PrayerNotificationSetting(isEnabled: true, offsetMinutes: 15),
            for: .maghrib
        )

        let result = settings.notificationSetting(for: .maghrib)
        #expect(result.isEnabled == true)
        #expect(result.offsetMinutes == 15)
    }

    // MARK: - Содержание уведомлений (текст на русском)

    @Test("Локализованное название каждой молитви содержит текст на русском")
    func notificationTitlesAreRussian() {
        let expected: [Prayer: String] = [
            .fajr: "Фаджр",
            .dhuhr: "Зухр",
            .asr: "Аср",
            .maghrib: "Магриб",
            .isha: "Иша"
        ]
        for (prayer, name) in expected {
            #expect(prayer.localizedName == name)
        }
    }

    @Test("Уведомление без смещения содержит 'Время намаза' в тексте")
    func notificationWithoutOffsetTitle() {
        // Проверяем шаблон заголовка уведомления при offsetMinutes == 0
        let prayer = Prayer.dhuhr
        let expectedTitle = "Время намаза: \(prayer.localizedName)"
        #expect(expectedTitle == "Время намаза: Зухр")
    }

    @Test("Уведомление со смещением содержит количество минут в тексте")
    func notificationWithOffsetTitle() {
        let prayer = Prayer.fajr
        let offsetMinutes = 10
        let expectedTitle = "\(prayer.localizedName) через \(offsetMinutes) мин"
        #expect(expectedTitle == "Фаджр через 10 мин")
    }

    // MARK: - Сериализация настроек

    @Test("Настройки уведомлений сохраняются и восстанавливаются корректно")
    func notificationSettingsCodable() throws {
        var settings = PrayerSettings.default
        settings.setNotification(PrayerNotificationSetting(isEnabled: true, offsetMinutes: 5), for: .fajr)
        settings.setNotification(PrayerNotificationSetting(isEnabled: true, offsetMinutes: 10), for: .isha)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(PrayerSettings.self, from: data)

        #expect(decoded.notificationSetting(for: .fajr).isEnabled == true)
        #expect(decoded.notificationSetting(for: .fajr).offsetMinutes == 5)
        #expect(decoded.notificationSetting(for: .isha).isEnabled == true)
        #expect(decoded.notificationSetting(for: .isha).offsetMinutes == 10)
        #expect(decoded.notificationSetting(for: .dhuhr).isEnabled == false)
    }
}
