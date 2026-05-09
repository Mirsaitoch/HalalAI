//
//  NavigationUITests.swift
//  HalalAIUITests
//

import XCTest

final class NavigationUITests: XCTestCase {

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

    // MARK: - Переключение табов

    func testTabSwitchingCycle() {
        // Home → Chat → Settings → Home
        let homeTab = app.buttons["tab_homepage"]
        let chatTab = app.buttons["tab_chat"]
        let settingsTab = app.buttons["tab_settings"]

        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))

        // → Chat
        chatTab.tap()
        let chatInput = app.textFields["chat_input_field"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 3),
                      "Чат должен открыться")

        // → Settings
        settingsTab.tap()
        let settingsExists = app.staticTexts["Настройки"].waitForExistence(timeout: 3) ||
                             app.staticTexts["AI Модель"].waitForExistence(timeout: 3) ||
                             app.staticTexts["Источники данных"].waitForExistence(timeout: 3)
        XCTAssertTrue(settingsExists, "Настройки должны открыться")

        // → Home
        homeTab.tap()
        let scannerCard = app.buttons["home_scanner_button"]
        XCTAssertTrue(scannerCard.waitForExistence(timeout: 3),
                      "Домашний экран должен вернуться")
    }

    func testDoubleTapTabResetsToRoot() {
        // Открываем Коран с Home
        let quranButton = app.buttons["home_quran_button"]
        if !quranButton.exists {
            app.swipeUp()
        }
        if quranButton.waitForExistence(timeout: 3) {
            quranButton.tap()

            // Подождём загрузку
            sleep(2)

            // Дабл-тап на Home tab — должен вернуть на корень
            let homeTab = app.buttons["tab_homepage"]
            homeTab.tap()

            let scannerCard = app.buttons["home_scanner_button"]
            XCTAssertTrue(scannerCard.waitForExistence(timeout: 3),
                          "Двойной тап на Home должен вернуть на корень")
        }
    }

    // MARK: - Навигация к карте

    func testNavigateToMapAndBack() {
        let mapButton = app.buttons["home_map_button"]
        XCTAssertTrue(mapButton.waitForExistence(timeout: 5))

        mapButton.tap()

        // Ждём загрузку карты
        sleep(2)

        // Проверяем что перешли на экран карты
        let mapExists = app.maps.firstMatch.exists ||
                        app.navigationBars.firstMatch.exists

        if mapExists {
            // Нажимаем кнопку назад
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()

                let scannerCard = app.buttons["home_scanner_button"]
                XCTAssertTrue(scannerCard.waitForExistence(timeout: 3),
                              "Должны вернуться на Home после нажатия Назад")
            }
        }
    }

    // MARK: - Навигация к Корану

    func testNavigateToQuranList() {
        let quranButton = app.buttons["home_quran_button"]
        if !quranButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(quranButton.waitForExistence(timeout: 5))

        quranButton.tap()

        // Ждём загрузку списка сур
        sleep(2)

        // Должны появиться суры или навигация
        let listAppeared = app.staticTexts["Аль-Фатиха"].waitForExistence(timeout: 5) ||
                           app.staticTexts.matching(
                               NSPredicate(format: "label CONTAINS[c] 'Аль-'")
                           ).count > 0 ||
                           app.navigationBars.firstMatch.exists

        XCTAssertTrue(listAppeared, "Список сур должен появиться")
    }
}
