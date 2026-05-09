//
//  AuthFlowUITests.swift
//  HalalAIUITests
//

import XCTest

final class AuthFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Экран входа

    func testLoginScreenElementsExist() {
        // Заголовок
        let title = app.staticTexts["Halal AI"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Заголовок 'Halal AI' должен быть виден")

        let subtitle = app.staticTexts["Войдите в свой аккаунт"]
        XCTAssertTrue(subtitle.exists, "Подзаголовок должен быть виден")

        // Кнопки
        let loginButton = app.buttons["login_button"]
        XCTAssertTrue(loginButton.exists, "Кнопка входа должна быть на экране")

        let registerLink = app.buttons["login_register_link"]
        XCTAssertTrue(registerLink.exists, "Ссылка на регистрацию должна быть на экране")

        let guestButton = app.buttons["login_guest_button"]
        XCTAssertTrue(guestButton.exists, "Кнопка гостевого входа должна быть на экране")
    }

    func testLoginButtonDisabledWithEmptyFields() {
        let loginButton = app.buttons["login_button"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        XCTAssertFalse(loginButton.isEnabled, "Кнопка входа должна быть неактивна при пустых полях")
    }

    func testNavigateToRegister() {
        let registerLink = app.buttons["login_register_link"]
        XCTAssertTrue(registerLink.waitForExistence(timeout: 5))

        registerLink.tap()

        let registerTitle = app.staticTexts["Создайте новый аккаунт"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 3),
                      "Экран регистрации должен появиться")
    }

    func testGuestLoginNavigatesToHome() {
        let guestButton = app.buttons["login_guest_button"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5))

        guestButton.tap()

        // После гостевого входа должен появиться домашний экран с табами
        let homeTab = app.buttons["tab_homepage"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5),
                      "Табы должны появиться после гостевого входа")
    }

    // MARK: - Экран регистрации

    func testRegisterScreenElementsExist() {
        // Переход на экран регистрации
        let registerLink = app.buttons["login_register_link"]
        XCTAssertTrue(registerLink.waitForExistence(timeout: 5))
        registerLink.tap()

        let subtitle = app.staticTexts["Создайте новый аккаунт"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: 3))

        // Кнопки
        let registerButton = app.buttons["register_button"]
        XCTAssertTrue(registerButton.exists, "Кнопка регистрации должна быть на экране")

        let loginLink = app.buttons["register_login_link"]
        XCTAssertTrue(loginLink.exists, "Ссылка на вход должна быть на экране")

        let guestButton = app.buttons["register_guest_button"]
        XCTAssertTrue(guestButton.exists, "Кнопка гостевого входа должна быть на экране")
    }

    func testRegisterButtonDisabledByDefault() {
        let registerLink = app.buttons["login_register_link"]
        XCTAssertTrue(registerLink.waitForExistence(timeout: 5))
        registerLink.tap()

        let registerButton = app.buttons["register_button"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: 3))
        XCTAssertFalse(registerButton.isEnabled,
                       "Кнопка регистрации должна быть неактивна при пустых полях")
    }

    func testNavigateFromRegisterToLogin() {
        // Login → Register
        let registerLink = app.buttons["login_register_link"]
        XCTAssertTrue(registerLink.waitForExistence(timeout: 5))
        registerLink.tap()

        let registerTitle = app.staticTexts["Создайте новый аккаунт"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 3))

        // Register → Login
        let loginLink = app.buttons["register_login_link"]
        XCTAssertTrue(loginLink.exists)
        loginLink.tap()

        let loginTitle = app.staticTexts["Войдите в свой аккаунт"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 3),
                      "Экран входа должен появиться при переходе назад")
    }

    func testGuestLoginFromRegisterScreen() {
        let registerLink = app.buttons["login_register_link"]
        XCTAssertTrue(registerLink.waitForExistence(timeout: 5))
        registerLink.tap()

        let guestButton = app.buttons["register_guest_button"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 3))
        guestButton.tap()

        let homeTab = app.buttons["tab_homepage"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5),
                      "Табы должны появиться после гостевого входа с экрана регистрации")
    }
}
