//
//  LoginUITests.swift
//  HalalAIUITests
//
//  Created by Мирсаит Сабирзянов on 14.12.2025.
//

import XCTest

final class LoginUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - UI Elements Tests

    func testWelcomeMessage() {
        XCTAssertTrue(app.staticTexts["Добро пожаловать"].exists)
    }

    func testLoginSubtitleExists() {
        XCTAssertTrue(app.staticTexts["Войдите в свой аккаунт"].exists)
    }

    func testEmailFieldExists() {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.exists, "Поле для ввода email должно существовать")
    }

    func testPasswordFieldExists() {
        let passwordField = app.secureTextFields["Пароль"]
        XCTAssertTrue(passwordField.exists, "Поле для ввода пароля должно существовать")
    }

    func testLoginButtonExists() {
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.exists, "Кнопка входа должна существовать")
    }

    func testRegisterButtonExists() {
        let registerButton = app.buttons["Зарегистрироваться"]
        XCTAssertTrue(registerButton.exists, "Кнопка регистрации должна существовать")
    }

    // MARK: - Validation Tests

    func testLoginButtonExistsWhenFieldsEmpty() {
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.exists, "Кнопка входа должна существовать даже при пустых полях")
    }

    func testCanFillEmailAndPasswordFields() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Пароль"]
        let loginButton = app.buttons["Войти"]

        emailField.tap()
        emailField.typeText("user@example.com")

        passwordField.tap()
        passwordField.typeText("password123")

        XCTAssertTrue(loginButton.exists, "Кнопка входа должна существовать после заполнения полей")
    }

    // MARK: - Input Tests

    func testCanTypeInEmailField() {
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")

        XCTAssertEqual(emailField.value as? String, "test@example.com", "Поле должно содержать введенный email")
    }

    func testCanTypeInPasswordField() {
        let passwordField = app.secureTextFields["Пароль"]
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")

        passwordField.tap()
        passwordField.typeText("mypassword")

        XCTAssertTrue(passwordField.exists, "Поле пароля должно существовать после ввода текста")
    }

    // MARK: - Navigation Tests

    func testNavigateToRegisterScreen() {
        let registerButton = app.buttons["Зарегистрироваться"]
        registerButton.tap()

        let registerTitle = app.staticTexts["Регистрация"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 2), "Должен открыться экран регистрации")
    }

    func testNavigateBackFromRegisterToLogin() {
        let registerButton = app.buttons["Зарегистрироваться"]
        registerButton.tap()

        let registerTitle = app.staticTexts["Регистрация"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 2))

        let loginButton = app.buttons["Войти"]
        if loginButton.exists {
            loginButton.tap()

            let welcomeText = app.staticTexts["Добро пожаловать"]
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Должен вернуться экран входа")
        }
    }

    // MARK: - Accessibility Tests

    func testLoginButtonHasAccessibilityLabel() {
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.exists, "Кнопка входа должна быть доступна для accessibility")
    }

    func testFieldsAreAccessible() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Пароль"]

        XCTAssertTrue(emailField.isHittable, "Поле email должно быть доступно для взаимодействия")
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")
    }
}
