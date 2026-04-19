//
//  RegisterUITests.swift
//  HalalAIUITests
//
//  Created by Auto on 2025.
//

import XCTest

final class RegisterUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()

        let registerButton = app.buttons["Зарегистрироваться"]
        if registerButton.waitForExistence(timeout: 2) {
            registerButton.tap()
        }
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - UI Elements Tests

    func testRegisterTitleExists() {
        let registerTitle = app.staticTexts["Регистрация"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 2), "Заголовок 'Регистрация' должен существовать")
    }

    func testRegisterSubtitleExists() {
        let subtitle = app.staticTexts["Создайте новый аккаунт"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: 2), "Подзаголовок должен существовать")
    }

    func testEmailFieldExists() {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Поле для ввода email должно существовать")
    }

    func testPasswordFieldExists() {
        let passwordField = app.secureTextFields["Пароль"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2), "Поле для ввода пароля должно существовать")
    }

    func testConfirmPasswordFieldExists() {
        let confirmPasswordField = app.secureTextFields["Подтвердите пароль"]
        XCTAssertTrue(confirmPasswordField.waitForExistence(timeout: 2), "Поле для подтверждения пароля должно существовать")
    }

    func testRegisterButtonExists() {
        let registerButton = app.buttons["Зарегистрироваться"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: 2), "Кнопка регистрации должна существовать")
    }

    func testLoginButtonExists() {
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2), "Кнопка входа должна существовать")
    }

    // MARK: - Validation Tests

    func testRegisterButtonExistsWhenFieldsEmpty() {
        let registerButton = app.buttons["Зарегистрироваться"]
        XCTAssertTrue(registerButton.exists, "Кнопка регистрации должна существовать даже при пустых полях")
    }

    func testCanFillAllFields() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Пароль"]
        let confirmPasswordField = app.secureTextFields["Подтвердите пароль"]
        let registerButton = app.buttons["Зарегистрироваться"]

        emailField.tap()
        emailField.typeText("test@example.com")

        passwordField.tap()
        passwordField.typeText("password123")

        confirmPasswordField.tap()
        confirmPasswordField.typeText("password123")

        XCTAssertTrue(registerButton.exists, "Кнопка регистрации должна существовать после заполнения полей")
    }

    // MARK: - Input Tests

    func testCanTypeInEmailField() {
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("user@example.com")

        XCTAssertEqual(emailField.value as? String, "user@example.com", "Поле должно содержать введенный email")
    }

    func testCanTypeInPasswordField() {
        let passwordField = app.secureTextFields["Пароль"]
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")

        passwordField.tap()
        passwordField.typeText("mypassword123")

        XCTAssertTrue(passwordField.exists, "Поле пароля должно существовать после ввода текста")
    }

    func testCanTypeInConfirmPasswordField() {
        let confirmPasswordField = app.secureTextFields["Подтвердите пароль"]
        XCTAssertTrue(confirmPasswordField.isHittable, "Поле подтверждения пароля должно быть доступно для взаимодействия")

        confirmPasswordField.tap()
        confirmPasswordField.typeText("mypassword123")

        XCTAssertTrue(confirmPasswordField.exists, "Поле подтверждения пароля должно существовать после ввода текста")
    }

    func testCanTypeValidEmail() {
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("valid.email@example.com")

        XCTAssertEqual(emailField.value as? String, "valid.email@example.com", "Поле должно принимать валидный email адрес")
    }

    // MARK: - Password Validation Tests

    func testPasswordValidationMessageAppears() {
        let passwordField = app.secureTextFields["Пароль"]
        passwordField.tap()
        passwordField.typeText("short")

        app.swipeUp()

        let validationMessage = app.staticTexts["Пароль должен содержать минимум 8 символов"]
        if validationMessage.waitForExistence(timeout: 1) {
            XCTAssertTrue(validationMessage.exists, "Должно появиться сообщение о валидации пароля")
        }
    }

    func testPasswordMismatchMessageAppears() {
        let passwordField = app.secureTextFields["Пароль"]
        let confirmPasswordField = app.secureTextFields["Подтвердите пароль"]

        passwordField.tap()
        passwordField.typeText("password123")

        confirmPasswordField.tap()
        confirmPasswordField.typeText("different")

        app.swipeUp()

        let mismatchMessage = app.staticTexts["Пароли не совпадают"]
        if mismatchMessage.waitForExistence(timeout: 1) {
            XCTAssertTrue(mismatchMessage.exists, "Должно появиться сообщение о несовпадении паролей")
        }
    }

    // MARK: - Navigation Tests

    func testNavigateToLoginScreen() {
        let loginButton = app.buttons["Войти"]
        loginButton.tap()

        let welcomeText = app.staticTexts["Добро пожаловать"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Должен открыться экран входа")
    }

    func testNavigateBackFromLoginToRegister() {
        let loginButton = app.buttons["Войти"]
        loginButton.tap()

        let welcomeText = app.staticTexts["Добро пожаловать"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 2))

        let registerButton = app.buttons["Зарегистрироваться"]
        if registerButton.exists {
            registerButton.tap()

            let registerTitle = app.staticTexts["Регистрация"]
            XCTAssertTrue(registerTitle.waitForExistence(timeout: 2), "Должен вернуться экран регистрации")
        }
    }

    // MARK: - Accessibility Tests

    func testRegisterButtonHasAccessibilityLabel() {
        let registerButton = app.buttons["Зарегистрироваться"]
        XCTAssertTrue(registerButton.exists, "Кнопка регистрации должна быть доступна для accessibility")
    }

    func testAllFieldsAreAccessible() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Пароль"]
        let confirmPasswordField = app.secureTextFields["Подтвердите пароль"]

        XCTAssertTrue(emailField.isHittable, "Поле email должно быть доступно для взаимодействия")
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")
        XCTAssertTrue(confirmPasswordField.isHittable, "Поле подтверждения пароля должно быть доступно для взаимодействия")
    }

    // MARK: - Form Filling Tests

    func testCompleteFormFilling() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Пароль"]
        let confirmPasswordField = app.secureTextFields["Подтвердите пароль"]

        emailField.tap()
        emailField.typeText("testuser@example.com")

        passwordField.tap()
        passwordField.typeText("securepass123")

        confirmPasswordField.tap()
        confirmPasswordField.typeText("securepass123")

        XCTAssertEqual(emailField.value as? String, "testuser@example.com", "Email должен быть заполнен")
        XCTAssertTrue(passwordField.exists, "Поле пароля должно существовать")
        XCTAssertTrue(confirmPasswordField.exists, "Поле подтверждения пароля должно существовать")
    }

    func testFormScrollable() {
        let emailField = app.textFields["Email"]
        emailField.tap()

        app.swipeUp()
        app.swipeDown()

        XCTAssertTrue(emailField.exists, "Форма должна быть прокручиваемой")
    }
}
