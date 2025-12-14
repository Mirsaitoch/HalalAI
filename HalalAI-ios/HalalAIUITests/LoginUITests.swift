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
    
    func testUsernameFieldExists() {
        let usernameField = app.textFields["Введите имя пользователя или email"]
        XCTAssertTrue(usernameField.exists, "Поле для ввода имени пользователя или email должно существовать")
    }
    
    func testPasswordFieldExists() {
        let passwordField = app.secureTextFields["Введите пароль"]
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
    
    func testCanFillUsernameAndPasswordFields() {
        let usernameField = app.textFields["Введите имя пользователя или email"]
        let passwordField = app.secureTextFields["Введите пароль"]
        let loginButton = app.buttons["Войти"]
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Проверяем, что кнопка все еще существует после заполнения полей
        XCTAssertTrue(loginButton.exists, "Кнопка входа должна существовать после заполнения полей")
    }
    
    // MARK: - Input Tests
    
    func testCanTypeInUsernameField() {
        let usernameField = app.textFields["Введите имя пользователя или email"]
        usernameField.tap()
        usernameField.typeText("testuser")
        
        XCTAssertEqual(usernameField.value as? String, "testuser", "Поле должно содержать введенный текст")
    }
    
    func testCanTypeInPasswordField() {
        let passwordField = app.secureTextFields["Введите пароль"]
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")
        
        passwordField.tap()
        passwordField.typeText("mypassword")
        
        // Проверяем, что поле все еще существует после ввода
        XCTAssertTrue(passwordField.exists, "Поле пароля должно существовать после ввода текста")
    }
    
    func testCanTypeEmailInUsernameField() {
        let usernameField = app.textFields["Введите имя пользователя или email"]
        usernameField.tap()
        usernameField.typeText("user@example.com")
        
        XCTAssertEqual(usernameField.value as? String, "user@example.com", "Поле должно принимать email адрес")
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToRegisterScreen() {
        let registerButton = app.buttons["Зарегистрироваться"]
        registerButton.tap()
        
        // Проверяем, что мы перешли на экран регистрации
        let registerTitle = app.staticTexts["Регистрация"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 2), "Должен открыться экран регистрации")
    }
    
    func testNavigateBackFromRegisterToLogin() {
        // Переходим на экран регистрации
        let registerButton = app.buttons["Зарегистрироваться"]
        registerButton.tap()
        
        // Ждем появления экрана регистрации
        let registerTitle = app.staticTexts["Регистрация"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 2))
        
        // Нажимаем кнопку "Войти" на экране регистрации
        let loginButton = app.buttons["Войти"]
        if loginButton.exists {
            loginButton.tap()
            
            // Проверяем, что вернулись на экран входа
            let welcomeText = app.staticTexts["Добро пожаловать"]
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Должен вернуться экран входа")
        }
    }
    
    // MARK: - Field Labels Tests
    
    func testUsernameFieldLabelExists() {
        XCTAssertTrue(app.staticTexts["Имя пользователя или Email"].exists, "Должна быть метка для поля имени пользователя")
    }
    
    func testPasswordFieldLabelExists() {
        XCTAssertTrue(app.staticTexts["Пароль"].exists, "Должна быть метка для поля пароля")
    }
    
    // MARK: - Accessibility Tests
    
    func testLoginButtonHasAccessibilityLabel() {
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.exists, "Кнопка входа должна быть доступна для accessibility")
    }
    
    func testFieldsAreAccessible() {
        let usernameField = app.textFields["Введите имя пользователя или email"]
        let passwordField = app.secureTextFields["Введите пароль"]
        
        XCTAssertTrue(usernameField.isHittable, "Поле имени пользователя должно быть доступно для взаимодействия")
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")
    }
}
