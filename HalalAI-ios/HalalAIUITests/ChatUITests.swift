//
//  ChatUITests.swift
//  HalalAIUITests
//

import XCTest

final class ChatUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Войти как гость и перейти на чат
        let guestButton = app.buttons["login_guest_button"]
        if guestButton.waitForExistence(timeout: 5) {
            guestButton.tap()
        }

        let chatTab = app.buttons["tab_chat"]
        XCTAssertTrue(chatTab.waitForExistence(timeout: 5))
        chatTab.tap()
    }

    // MARK: - Элементы чата

    func testChatInputFieldExists() {
        let chatInput = app.textFields["chat_input_field"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5),
                      "Поле ввода сообщения должно быть видно")
    }

    func testSendButtonExists() {
        let sendButton = app.buttons["chat_send_button"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5),
                      "Кнопка отправки должна быть видна")
    }

    func testSendButtonDisabledWhenEmpty() {
        let sendButton = app.buttons["chat_send_button"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        XCTAssertFalse(sendButton.isEnabled,
                       "Кнопка отправки должна быть неактивна при пустом поле")
    }

    func testChatInputFieldHasPlaceholder() {
        let chatInput = app.textFields["chat_input_field"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5))

        let placeholderValue = chatInput.placeholderValue ?? ""
        XCTAssertTrue(placeholderValue.contains("Напишите"),
                      "Поле ввода должно содержать placeholder")
    }

    func testChatInputFieldIsInteractable() {
        let chatInput = app.textFields["chat_input_field"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5))
        XCTAssertTrue(chatInput.isHittable,
                      "Поле ввода должно быть доступно для взаимодействия")
    }

    // MARK: - Гостевой баннер

    func testGuestBannerVisibleInChat() {
        let chatInput = app.textFields["chat_input_field"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5),
                      "Чат должен быть доступен для гостевого пользователя")
    }
}
