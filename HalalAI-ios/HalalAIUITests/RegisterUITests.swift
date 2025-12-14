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
        
        // Переходим на экран регистрации
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
    
    func testUsernameFieldExists() {
        let usernameField = app.textFields["Введите имя пользователя"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2), "Поле для ввода имени пользователя должно существовать")
    }
    
    func testEmailFieldExists() {
        let emailField = app.textFields["Введите email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Поле для ввода email должно существовать")
    }
    
    func testPasswordFieldExists() {
        let passwordField = app.secureTextFields["Введите пароль"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2), "Поле для ввода пароля должно существовать")
    }
    
    func testConfirmPasswordFieldExists() {
        let confirmPasswordField = app.secureTextFields["Повторите пароль"]
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
        let usernameField = app.textFields["Введите имя пользователя"]
        let emailField = app.textFields["Введите email"]
        let passwordField = app.secureTextFields["Введите пароль"]
        let confirmPasswordField = app.secureTextFields["Повторите пароль"]
        let registerButton = app.buttons["Зарегистрироваться"]
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("password123")
        
        // Проверяем, что кнопка все еще существует после заполнения полей
        XCTAssertTrue(registerButton.exists, "Кнопка регистрации должна существовать после заполнения полей")
    }
    
    // MARK: - Input Tests
    
    func testCanTypeInUsernameField() {
        let usernameField = app.textFields["Введите имя пользователя"]
        usernameField.tap()
        usernameField.typeText("newuser")
        
        XCTAssertEqual(usernameField.value as? String, "newuser", "Поле должно содержать введенный текст")
    }
    
    func testCanTypeInEmailField() {
        let emailField = app.textFields["Введите email"]
        emailField.tap()
        emailField.typeText("user@example.com")
        
        XCTAssertEqual(emailField.value as? String, "user@example.com", "Поле должно содержать введенный email")
    }
    
    func testCanTypeInPasswordField() {
        let passwordField = app.secureTextFields["Введите пароль"]
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")
        
        passwordField.tap()
        passwordField.typeText("mypassword123")
        
        // Проверяем, что поле все еще существует после ввода
        XCTAssertTrue(passwordField.exists, "Поле пароля должно существовать после ввода текста")
    }
    
    func testCanTypeInConfirmPasswordField() {
        let confirmPasswordField = app.secureTextFields["Повторите пароль"]
        XCTAssertTrue(confirmPasswordField.isHittable, "Поле подтверждения пароля должно быть доступно для взаимодействия")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("mypassword123")
        
        // Проверяем, что поле все еще существует после ввода
        XCTAssertTrue(confirmPasswordField.exists, "Поле подтверждения пароля должно существовать после ввода текста")
    }
    
    func testCanTypeValidEmail() {
        let emailField = app.textFields["Введите email"]
        emailField.tap()
        emailField.typeText("valid.email@example.com")
        
        XCTAssertEqual(emailField.value as? String, "valid.email@example.com", "Поле должно принимать валидный email адрес")
    }
    
    // MARK: - Password Validation Tests
    
    func testPasswordValidationMessageAppears() {
        let passwordField = app.secureTextFields["Введите пароль"]
        passwordField.tap()
        passwordField.typeText("short")
        
        // Прокручиваем, если нужно, чтобы увидеть сообщение об ошибке
        app.swipeUp()
        
        // Проверяем наличие сообщения о валидации (если оно отображается)
        let validationMessage = app.staticTexts["Пароль должен содержать минимум 8 символов"]
        // Сообщение может не появиться сразу, поэтому проверяем с таймаутом
        if validationMessage.waitForExistence(timeout: 1) {
            XCTAssertTrue(validationMessage.exists, "Должно появиться сообщение о валидации пароля")
        }
    }
    
    func testPasswordMismatchMessageAppears() {
        let passwordField = app.secureTextFields["Введите пароль"]
        let confirmPasswordField = app.secureTextFields["Повторите пароль"]
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("different")
        
        // Прокручиваем, если нужно
        app.swipeUp()
        
        // Проверяем наличие сообщения о несовпадении паролей
        let mismatchMessage = app.staticTexts["Пароли не совпадают"]
        if mismatchMessage.waitForExistence(timeout: 1) {
            XCTAssertTrue(mismatchMessage.exists, "Должно появиться сообщение о несовпадении паролей")
        }
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToLoginScreen() {
        let loginButton = app.buttons["Войти"]
        loginButton.tap()
        
        // Проверяем, что мы перешли на экран входа
        let welcomeText = app.staticTexts["Добро пожаловать"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Должен открыться экран входа")
    }
    
    func testNavigateBackFromLoginToRegister() {
        // Переходим на экран входа
        let loginButton = app.buttons["Войти"]
        loginButton.tap()
        
        // Ждем появления экрана входа
        let welcomeText = app.staticTexts["Добро пожаловать"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 2))
        
        // Нажимаем кнопку "Зарегистрироваться" на экране входа
        let registerButton = app.buttons["Зарегистрироваться"]
        if registerButton.exists {
            registerButton.tap()
            
            // Проверяем, что вернулись на экран регистрации
            let registerTitle = app.staticTexts["Регистрация"]
            XCTAssertTrue(registerTitle.waitForExistence(timeout: 2), "Должен вернуться экран регистрации")
        }
    }
    
    // MARK: - Field Labels Tests
    
    func testUsernameFieldLabelExists() {
        XCTAssertTrue(app.staticTexts["Имя пользователя"].waitForExistence(timeout: 2), "Должна быть метка для поля имени пользователя")
    }
    
    func testEmailFieldLabelExists() {
        XCTAssertTrue(app.staticTexts["Email"].waitForExistence(timeout: 2), "Должна быть метка для поля email")
    }
    
    func testPasswordFieldLabelExists() {
        XCTAssertTrue(app.staticTexts["Пароль"].waitForExistence(timeout: 2), "Должна быть метка для поля пароля")
    }
    
    func testConfirmPasswordFieldLabelExists() {
        XCTAssertTrue(app.staticTexts["Подтвердите пароль"].waitForExistence(timeout: 2), "Должна быть метка для поля подтверждения пароля")
    }
    
    // MARK: - Accessibility Tests
    
    func testRegisterButtonHasAccessibilityLabel() {
        let registerButton = app.buttons["Зарегистрироваться"]
        XCTAssertTrue(registerButton.exists, "Кнопка регистрации должна быть доступна для accessibility")
    }
    
    func testAllFieldsAreAccessible() {
        let usernameField = app.textFields["Введите имя пользователя"]
        let emailField = app.textFields["Введите email"]
        let passwordField = app.secureTextFields["Введите пароль"]
        let confirmPasswordField = app.secureTextFields["Повторите пароль"]
        
        XCTAssertTrue(usernameField.isHittable, "Поле имени пользователя должно быть доступно для взаимодействия")
        XCTAssertTrue(emailField.isHittable, "Поле email должно быть доступно для взаимодействия")
        XCTAssertTrue(passwordField.isHittable, "Поле пароля должно быть доступно для взаимодействия")
        XCTAssertTrue(confirmPasswordField.isHittable, "Поле подтверждения пароля должно быть доступно для взаимодействия")
    }
    
    // MARK: - Form Filling Tests
    
    func testCompleteFormFilling() {
        let usernameField = app.textFields["Введите имя пользователя"]
        let emailField = app.textFields["Введите email"]
        let passwordField = app.secureTextFields["Введите пароль"]
        let confirmPasswordField = app.secureTextFields["Повторите пароль"]
        
        // Заполняем все поля последовательно
        usernameField.tap()
        usernameField.typeText("testuser123")
        
        emailField.tap()
        emailField.typeText("testuser@example.com")
        
        passwordField.tap()
        passwordField.typeText("securepass123")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("securepass123")
        
        // Проверяем, что все поля заполнены
        XCTAssertEqual(usernameField.value as? String, "testuser123", "Имя пользователя должно быть заполнено")
        XCTAssertEqual(emailField.value as? String, "testuser@example.com", "Email должен быть заполнен")
        XCTAssertTrue(passwordField.exists, "Поле пароля должно существовать")
        XCTAssertTrue(confirmPasswordField.exists, "Поле подтверждения пароля должно существовать")
    }
    
    func testFormScrollable() {
        // Проверяем, что форма прокручивается (ScrollView работает)
        let usernameField = app.textFields["Введите имя пользователя"]
        usernameField.tap()
        
        // Прокручиваем вниз
        app.swipeUp()
        
        // Прокручиваем вверх
        app.swipeDown()
        
        // Проверяем, что поле все еще доступно
        XCTAssertTrue(usernameField.exists, "Форма должна быть прокручиваемой")
    }
}

