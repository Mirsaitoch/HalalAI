//
//  HomeScreenUITests.swift
//  HalalAIUITests
//

import XCTest

final class HomeScreenUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Войти как гость
        let guestButton = app.buttons["login_guest_button"]
        if guestButton.waitForExistence(timeout: 5) {
            guestButton.tap()
        }
    }

    // MARK: - Таб-бар

    func testTabBarExists() {
        let homeTab = app.buttons["tab_homepage"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "Таб 'Главная' должен быть виден")

        let chatTab = app.buttons["tab_chat"]
        XCTAssertTrue(chatTab.exists, "Таб 'Чат' должен быть виден")

        let settingsTab = app.buttons["tab_settings"]
        XCTAssertTrue(settingsTab.exists, "Таб 'Настройки' должен быть виден")
    }

    func testSwitchToChatTab() {
        let chatTab = app.buttons["tab_chat"]
        XCTAssertTrue(chatTab.waitForExistence(timeout: 5))

        chatTab.tap()

        // Должен появиться input bar чата
        let chatInput = app.textFields["chat_input_field"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 3),
                      "Поле ввода чата должно появиться при переходе на таб 'Чат'")
    }

    func testSwitchToSettingsTab() {
        let settingsTab = app.buttons["tab_settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))

        settingsTab.tap()

        // Проверяем что Settings экран загрузился (ищем характерный текст)
        let exists = app.staticTexts["Настройки"].waitForExistence(timeout: 3) ||
                     app.staticTexts["AI Модель"].waitForExistence(timeout: 3) ||
                     app.staticTexts["Источники данных"].waitForExistence(timeout: 3)
        XCTAssertTrue(exists, "Экран настроек должен отобразиться")
    }

    func testSwitchBackToHomeTab() {
        let chatTab = app.buttons["tab_chat"]
        XCTAssertTrue(chatTab.waitForExistence(timeout: 5))
        chatTab.tap()

        let homeTab = app.buttons["tab_homepage"]
        homeTab.tap()

        // Должны быть видны карточки главного экрана
        let scannerButton = app.buttons["home_scanner_button"]
        XCTAssertTrue(scannerButton.waitForExistence(timeout: 3),
                      "Карточка сканера должна быть видна на главном экране")
    }

    // MARK: - Карточки главного экрана

    func testHomeScreenCardsExist() {
        let scannerButton = app.buttons["home_scanner_button"]
        XCTAssertTrue(scannerButton.waitForExistence(timeout: 5),
                      "Карточка 'Сканировать состав' должна быть видна")

        let chatButton = app.buttons["home_chat_button"]
        XCTAssertTrue(chatButton.exists, "Карточка 'Чат с AI' должна быть видна")

        let mapButton = app.buttons["home_map_button"]
        XCTAssertTrue(mapButton.exists, "Карточка 'Найти заведение' должна быть видна")
    }

    func testHomeScreenQuranCardExists() {
        let quranButton = app.buttons["home_quran_button"]
        // Может потребоваться скролл
        if !quranButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(quranButton.waitForExistence(timeout: 3),
                      "Карточка 'Изучай Ислам' должна быть видна")
    }

    func testTapMapCardNavigates() {
        let mapButton = app.buttons["home_map_button"]
        XCTAssertTrue(mapButton.waitForExistence(timeout: 5))

        mapButton.tap()

        // Должна появиться карта или экран поиска
        let mapExists = app.maps.firstMatch.waitForExistence(timeout: 5) ||
                        app.staticTexts["Халяль заведения"].waitForExistence(timeout: 5)
        XCTAssertTrue(mapExists, "Экран карты должен появиться")
    }

    func testTapQuranCardNavigates() {
        let quranButton = app.buttons["home_quran_button"]
        if !quranButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(quranButton.waitForExistence(timeout: 5))

        quranButton.tap()

        // Должен появиться список сур
        let listExists = app.staticTexts["Аль-Фатиха"].waitForExistence(timeout: 5) ||
                         app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(listExists, "Список сур Корана должен появиться")
    }
}
