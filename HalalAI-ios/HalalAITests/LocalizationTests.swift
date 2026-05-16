//
//  LocalizationTests.swift
//  HalalAITests
//
//  Проверка локализации интерфейса на русский язык (раздел 4.4.3 диплома, требование з).
//

import Testing
@testable import HalalAI

struct LocalizationTests {

    // MARK: - Сканер: статусы ингредиентов

    @Test("Статусы ингредиентов отображаются на русском языке",
          arguments: [
            (IngredientStatus.halal,    "Халяль"),
            (IngredientStatus.haram,    "Харам"),
            (IngredientStatus.mushbooh, "Сомнительно"),
            (IngredientStatus.unknown,  "Неизвестно")
          ])
    func ingredientStatusDisplayNames(status: IngredientStatus, expected: String) {
        #expect(status.displayName == expected)
    }

    // MARK: - Молитвы: названия

    @Test("Названия молитв отображаются на русском языке",
          arguments: [
            (Prayer.fajr,    "Фаджр"),
            (Prayer.sunrise, "Шурук"),
            (Prayer.dhuhr,   "Зухр"),
            (Prayer.asr,     "Аср"),
            (Prayer.maghrib, "Магриб"),
            (Prayer.isha,    "Иша")
          ])
    func prayerLocalizedNames(prayer: Prayer, expected: String) {
        #expect(prayer.localizedName == expected)
    }

    // MARK: - Молитвы: методы расчёта

    @Test("Методы расчёта времени молитв имеют непустые локализованные названия",
          arguments: PrayerCalculationMethod.allCases)
    func calculationMethodHasLocalizedName(method: PrayerCalculationMethod) {
        #expect(method.localizedName.isEmpty == false)
    }

    // MARK: - Коран: структура

    @Test("Название суры содержит порядковый номер и название на русском")
    func suraDisplayTitleFormat() {
        let sura = Sura(id: 1, index: 1, title: "Аль-Фатиха", subtitle: "Открывающая", verses: [])
        // Формат: "1. Аль-Фатиха"
        #expect(sura.displayTitle.hasPrefix("1."))
        #expect(sura.displayTitle.contains("Аль-Фатиха"))
    }

    @Test("Подзаголовок суры содержит перевод названия")
    func suraSubtitleIsPresent() {
        let sura = Sura(id: 2, index: 2, title: "Аль-Бакара", subtitle: "Корова", verses: [])
        #expect(sura.subtitle.isEmpty == false)
        #expect(sura.subtitle == "Корова")
    }

    // MARK: - Чат: роли сообщений

    @Test("Роль пользователя кодируется как 'user'")
    func userRoleEncoding() {
        #expect(Role.user.rawValue == "user")
    }

    @Test("Роль ассистента кодируется как 'assistant'")
    func assistantRoleEncoding() {
        #expect(Role.assistant.rawValue == "assistant")
    }

    // MARK: - Уведомления: текст на русском

    @Test("Текст уведомления о наступлении молитвы содержит русское название")
    func notificationTextContainsRussianPrayerName() {
        for prayer in Prayer.notifiablePrayers {
            let title = "Время намаза: \(prayer.localizedName)"
            // Проверяем, что название не содержит латиницы (все русские)
            let latinCharacters = title.unicodeScalars.filter { scalar in
                (65...90).contains(scalar.value) || (97...122).contains(scalar.value)
            }
            #expect(latinCharacters.isEmpty,
                    "Уведомление для \(prayer) должно содержать только русский текст, получено: '\(title)'")
        }
    }
}
