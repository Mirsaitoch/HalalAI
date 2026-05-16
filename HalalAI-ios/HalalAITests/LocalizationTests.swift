//
//  LocalizationTests.swift
//  HalalAITests
//
//  Проверка локализации интерфейса (раздел 4.4.3 диплома, требование з).
//  Покрывает: AppLanguage, LanguageStore, переключение языка, ключи обоих .strings-файлов.
//

import Testing
@testable import HalalAI
import Foundation

// MARK: - AppLanguage

struct AppLanguageTests {

    @Test("Перечисление содержит ровно два языка")
    func allCasesCount() {
        #expect(AppLanguage.allCases.count == 2)
    }

    @Test("rawValue русского языка — 'ru'")
    func russianRawValue() {
        #expect(AppLanguage.russian.rawValue == "ru")
    }

    @Test("rawValue английского языка — 'en'")
    func englishRawValue() {
        #expect(AppLanguage.english.rawValue == "en")
    }

    @Test("Отображаемое имя русского — 'Русский'")
    func russianDisplayName() {
        #expect(AppLanguage.russian.displayName == "Русский")
    }

    @Test("Отображаемое имя английского — 'English'")
    func englishDisplayName() {
        #expect(AppLanguage.english.displayName == "English")
    }

    @Test("Locale русского — ru_RU")
    func russianLocale() {
        #expect(AppLanguage.russian.locale.identifier == "ru_RU")
    }

    @Test("Locale английского — en_US")
    func englishLocale() {
        #expect(AppLanguage.english.locale.identifier == "en_US")
    }

    @Test("Инициализация из rawValue возвращает корректный кейс")
    func initFromRawValue() {
        #expect(AppLanguage(rawValue: "ru") == .russian)
        #expect(AppLanguage(rawValue: "en") == .english)
        #expect(AppLanguage(rawValue: "fr") == nil)
        #expect(AppLanguage(rawValue: "")  == nil)
    }
}

// MARK: - LanguageStore

private let defaultsKey = "HalalAI.appLanguage"

@MainActor
struct LanguageStoreTests {

    // MARK: Вспомогательные функции

    /// Создаёт чистый LanguageStore с заданным языком (не затрагивает UserDefaults).
    private func makeStore(language: AppLanguage) -> LanguageStore {
        let store = LanguageStore()
        store.currentLanguage = language
        return store
    }

    /// Очищает сохранённый язык из UserDefaults.
    private func clearSaved() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    // MARK: Инициализация и персистентность

    @Test("При отсутствии сохранённого языка используется русский по умолчанию")
    func defaultLanguageIsRussian() {
        clearSaved()
        let store = LanguageStore()
        #expect(store.currentLanguage == .russian)
        clearSaved()
    }

    @Test("При наличии сохранённого 'en' загружается английский")
    func loadsPersistedEnglish() {
        UserDefaults.standard.set("en", forKey: defaultsKey)
        let store = LanguageStore()
        #expect(store.currentLanguage == .english)
        clearSaved()
    }

    @Test("При наличии сохранённого 'ru' загружается русский")
    func loadsPersistedRussian() {
        UserDefaults.standard.set("ru", forKey: defaultsKey)
        let store = LanguageStore()
        #expect(store.currentLanguage == .russian)
        clearSaved()
    }

    @Test("Некорректное сохранённое значение заменяется русским")
    func invalidSavedValueFallsBackToRussian() {
        UserDefaults.standard.set("xx", forKey: defaultsKey)
        let store = LanguageStore()
        #expect(store.currentLanguage == .russian)
        clearSaved()
    }

    @Test("Смена языка сохраняется в UserDefaults")
    func languageChangePersistsInUserDefaults() {
        clearSaved()
        let store = LanguageStore()
        store.currentLanguage = .english
        let saved = UserDefaults.standard.string(forKey: defaultsKey)
        #expect(saved == "en")
        clearSaved()
    }

    @Test("Повторная смена языка обновляет значение в UserDefaults")
    func languageChangeUpdatesUserDefaults() {
        clearSaved()
        let store = LanguageStore()
        store.currentLanguage = .english
        store.currentLanguage = .russian
        let saved = UserDefaults.standard.string(forKey: defaultsKey)
        #expect(saved == "ru")
        clearSaved()
    }

    // MARK: Переключение языка

    @Test("После переключения на английский t() возвращает английский перевод")
    func switchToEnglishChangesTranslations() {
        let store = makeStore(language: .russian)
        #expect(store.t("prayer.today") == "Сегодня")
        store.currentLanguage = .english
        #expect(store.t("prayer.today") == "Today")
    }

    @Test("После переключения обратно на русский t() возвращает русский перевод")
    func switchBackToRussian() {
        let store = makeStore(language: .english)
        store.currentLanguage = .russian
        #expect(store.t("prayer.today") == "Сегодня")
    }

    @Test("Несуществующий ключ возвращается как есть (fallback)")
    func unknownKeyReturnsSelf() {
        let store = makeStore(language: .russian)
        let key = "nonexistent.key.xyz"
        #expect(store.t(key) == key)
    }

    // MARK: Русские переводы — все пространства имён

    @Test("Русские переводы: вкладки",
          arguments: [
            ("tab.home",     "Главная"),
            ("tab.chat",     "Чат"),
            ("tab.settings", "Настройки"),
          ])
    func ruTabs(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: общие строки",
          arguments: [
            ("common.back",  "Назад"),
            ("common.error", "Ошибка"),
            ("common.ok",    "OK"),
            ("common.copy",  "Копировать"),
            ("common.retry", "Повторить отправку"),
            ("common.connection_error", "Ошибка соединения"),
          ])
    func ruCommon(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: авторизация (вход)",
          arguments: [
            ("auth.login.button",   "Войти"),
            ("auth.login.email",    "Email"),
            ("auth.login.password", "Пароль"),
            ("auth.login.guest",    "Продолжить без аккаунта"),
          ])
    func ruAuthLogin(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: авторизация (регистрация)",
          arguments: [
            ("auth.register.button",           "Зарегистрироваться"),
            ("auth.register.password_mismatch","Пароли не совпадают"),
          ])
    func ruAuthRegister(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: гостевой режим",
          arguments: [
            ("guest.title",         "Нужна авторизация"),
            ("guest.sign_in",       "Войти"),
            ("guest.banner.title",  "Войдите в аккаунт"),
            ("guest.banner.subtitle","Чтобы использовать чат и сканер"),
            ("guest.account_needed","Нужен аккаунт"),
          ])
    func ruGuest(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: настройки",
          arguments: [
            ("settings.title",   "Настройки"),
            ("settings.logout",  "Выйти из аккаунта"),
            ("settings.language","Язык интерфейса"),
          ])
    func ruSettings(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: чат",
          arguments: [
            ("chat.clear",          "Очистить чат"),
            ("chat.feature_name",   "ИИ-чат"),
            ("chat.empty.greeting", "Ассаламу алейкум 👋"),
          ])
    func ruChat(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: сканер",
          arguments: [
            ("scanner.title",   "Сканирование состава"),
            ("scanner.camera",  "Сфотографировать"),
            ("scanner.check",   "Проверить"),
          ])
    func ruScanner(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: результаты анализа",
          arguments: [
            ("results.title",        "Результаты анализа"),
            ("results.haram_section","Запрещенные ингредиенты"),
            ("results.all_section",  "Все ингредиенты"),
          ])
    func ruResults(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: статусы ингредиентов",
          arguments: [
            ("ingredient.status.halal",    "Халяль"),
            ("ingredient.status.haram",    "Харам"),
            ("ingredient.status.mushbooh", "Сомнительно"),
            ("ingredient.status.unknown",  "Неизвестно"),
          ])
    func ruIngredientStatuses(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: главный экран",
          arguments: [
            ("home.scan.title",  "Сканировать состав"),
            ("home.chat.title",  "Чат с AI"),
            ("home.map.title",   "Найти заведение"),
            ("home.quran.title", "Изучай Ислам"),
          ])
    func ruHome(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: время намаза",
          arguments: [
            ("prayer.title",     "Время намаза"),
            ("prayer.today",     "Сегодня"),
            ("prayer.tomorrow",  "Завтра"),
            ("prayer.yesterday", "Вчера"),
            ("prayer.all_passed","Все намазы прошли"),
          ])
    func ruPrayer(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: названия намазов",
          arguments: [
            ("prayer.name.fajr",    "Фаджр"),
            ("prayer.name.sunrise", "Шурук"),
            ("prayer.name.dhuhr",   "Зухр"),
            ("prayer.name.asr",     "Аср"),
            ("prayer.name.maghrib", "Магриб"),
            ("prayer.name.isha",    "Иша"),
          ])
    func ruPrayerNames(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: настройки уведомлений",
          arguments: [
            ("prayer.settings.at_prayer",  "Ровно в намаз"),
            ("prayer.settings.before_5",   "За 5 минут"),
            ("prayer.settings.before_10",  "За 10 минут"),
            ("prayer.settings.before_15",  "За 15 минут"),
            ("prayer.settings.before_30",  "За 30 минут"),
            ("prayer.settings.reset",      "Сбросить"),
          ])
    func ruPrayerSettings(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: карта",
          arguments: [
            ("map.title",       "Халяль места"),
            ("map.searching",   "Поиск халяль мест..."),
            ("map.directions",  "Построить маршрут"),
          ])
    func ruMap(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    @Test("Русские переводы: Коран",
          arguments: [
            ("quran.title",           "Коран"),
            ("quran.continue_reading","Продолжить чтение"),
            ("quran.verse_of_day",    "Аят дня"),
            ("quran.font_size",       "Размер текста"),
          ])
    func ruQuran(key: String, expected: String) {
        #expect(makeStore(language: .russian).t(key) == expected)
    }

    // MARK: Английские переводы — все пространства имён

    @Test("Английские переводы: вкладки",
          arguments: [
            ("tab.home",     "Home"),
            ("tab.chat",     "Chat"),
            ("tab.settings", "Settings"),
          ])
    func enTabs(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: общие строки",
          arguments: [
            ("common.back",  "Back"),
            ("common.error", "Error"),
            ("common.copy",  "Copy"),
            ("common.retry", "Retry"),
            ("common.connection_error", "Connection error"),
          ])
    func enCommon(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: авторизация",
          arguments: [
            ("auth.login.button",   "Sign in"),
            ("auth.login.guest",    "Continue without account"),
            ("auth.register.button","Register"),
            ("auth.register.password_mismatch", "Passwords do not match"),
          ])
    func enAuth(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: гостевой режим",
          arguments: [
            ("guest.title",          "Authorization required"),
            ("guest.sign_in",        "Sign in"),
            ("guest.banner.title",   "Sign in"),
            ("guest.account_needed", "Account required"),
          ])
    func enGuest(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: статусы ингредиентов",
          arguments: [
            ("ingredient.status.halal",    "Halal"),
            ("ingredient.status.haram",    "Haram"),
            ("ingredient.status.mushbooh", "Questionable"),
            ("ingredient.status.unknown",  "Unknown"),
          ])
    func enIngredientStatuses(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: время намаза",
          arguments: [
            ("prayer.title",     "Prayer times"),
            ("prayer.today",     "Today"),
            ("prayer.tomorrow",  "Tomorrow"),
            ("prayer.yesterday", "Yesterday"),
            ("prayer.all_passed","All prayers have passed"),
          ])
    func enPrayer(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: названия намазов",
          arguments: [
            ("prayer.name.fajr",    "Fajr"),
            ("prayer.name.sunrise", "Shuruq"),
            ("prayer.name.dhuhr",   "Dhuhr"),
            ("prayer.name.asr",     "Asr"),
            ("prayer.name.maghrib", "Maghrib"),
            ("prayer.name.isha",    "Isha"),
          ])
    func enPrayerNames(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: настройки уведомлений",
          arguments: [
            ("prayer.settings.at_prayer", "At prayer time"),
            ("prayer.settings.before_5",  "5 minutes before"),
            ("prayer.settings.before_10", "10 minutes before"),
            ("prayer.settings.before_15", "15 minutes before"),
            ("prayer.settings.before_30", "30 minutes before"),
            ("prayer.settings.reset",     "Reset"),
          ])
    func enPrayerSettings(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: карта",
          arguments: [
            ("map.title",      "Halal places"),
            ("map.searching",  "Searching for halal places..."),
            ("map.directions", "Get directions"),
          ])
    func enMap(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: Коран",
          arguments: [
            ("quran.title",           "Quran"),
            ("quran.continue_reading","Continue reading"),
            ("quran.verse_of_day",    "Verse of the day"),
            ("quran.font_size",       "Font size"),
          ])
    func enQuran(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    @Test("Английские переводы: удалённая модель",
          arguments: [
            ("model.section",     "Remote model"),
            ("model.custom",      "Use custom model"),
            ("model.rag",         "Use RAG (semantic search)"),
            ("model.refresh",     "Refresh model list"),
          ])
    func enModel(key: String, expected: String) {
        #expect(makeStore(language: .english).t(key) == expected)
    }

    // MARK: Полнота переводов

    @Test("Все ключи переведены на оба языка (выборка по пространствам имён)",
          arguments: [
            "tab.home", "common.back", "auth.login.button", "auth.register.button",
            "guest.title", "settings.title", "chat.clear", "scanner.title",
            "results.title", "ingredient.status.halal", "home.scan.title",
            "prayer.title", "prayer.name.fajr", "prayer.settings.at_prayer",
            "map.title", "model.section", "quran.title",
          ])
    func keyExistsInBothLanguages(key: String) {
        let ru = makeStore(language: .russian)
        let en = makeStore(language: .english)
        // Если ключ отсутствует, t() возвращает сам ключ
        #expect(ru.t(key) != key, "Ключ '\(key)' не найден в русском .strings")
        #expect(en.t(key) != key, "Ключ '\(key)' не найден в английском .strings")
    }

    @Test("Русский и английский переводы одного ключа отличаются")
    func ruAndEnTranslationsDiffer() {
        let keysExpectedToDiffer = [
            "prayer.today", "prayer.tomorrow", "prayer.title",
            "scanner.title", "results.title", "map.title",
            "quran.title", "guest.title",
        ]
        for key in keysExpectedToDiffer {
            let ru = makeStore(language: .russian).t(key)
            let en = makeStore(language: .english).t(key)
            #expect(ru != en, "Ключ '\(key)': русский и английский переводы совпадают ('\(ru)')")
        }
    }

    // MARK: Ранее существующие требования (обратная совместимость)

    @Test("IngredientStatus.displayName возвращает русское значение",
          arguments: [
            (IngredientStatus.halal,    "Халяль"),
            (IngredientStatus.haram,    "Харам"),
            (IngredientStatus.mushbooh, "Сомнительно"),
            (IngredientStatus.unknown,  "Неизвестно")
          ])
    func ingredientStatusDisplayNames(status: IngredientStatus, expected: String) {
        #expect(status.displayName == expected)
    }

    @Test("Prayer.localizedName возвращает русское название",
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
}
