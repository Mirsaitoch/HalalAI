//
//  ScannerUITests.swift
//  HalalAIUITests
//

import XCTest

final class ScannerUITests: XCTestCase {

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

    // MARK: - Навигация к сканеру

    func testGuestCannotOpenScanner() {
        let scannerButton = app.buttons["home_scanner_button"]
        XCTAssertTrue(scannerButton.waitForExistence(timeout: 5))

        scannerButton.tap()

        // Для гостя сканер заблокирован — должен показать оверлей авторизации
        // или не перейти на экран сканера
        let guestPrompt = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'авторизуйтесь' OR label CONTAINS[c] 'войдите' OR label CONTAINS[c] 'регистрации' OR label CONTAINS[c] 'сканирование'")
        )

        // Либо промпт авторизации, либо остались на домашнем экране
        let stayedHome = app.buttons["home_scanner_button"].exists
        let showedPrompt = guestPrompt.count > 0

        XCTAssertTrue(stayedHome || showedPrompt,
                      "Гость не должен иметь полный доступ к сканеру")
    }
}
