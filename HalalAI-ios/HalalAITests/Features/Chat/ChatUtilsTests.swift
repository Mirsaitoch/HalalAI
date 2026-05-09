//
//  ChatUtilsTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct ChatUtilsTests {

    // MARK: - Message Validation

    @Test("Valid messages pass validation",
          arguments: ["Привет", "Hello", "a", String(repeating: "x", count: 2000)])
    func validMessages(text: String) {
        #expect(ChatUtils.isValidMessage(text) == true)
    }

    @Test("Empty and whitespace-only messages are invalid",
          arguments: ["", "   ", "\n", "\t", "  \n  "])
    func invalidEmptyMessages(text: String) {
        #expect(ChatUtils.isValidMessage(text) == false)
    }

    @Test("Messages exceeding 2000 characters are invalid")
    func tooLongMessageInvalid() {
        let longText = String(repeating: "a", count: 2001)
        #expect(ChatUtils.isValidMessage(longText) == false)
    }

    // MARK: - Message Sanitization

    @Test("sanitizeMessage trims whitespace and newlines")
    func sanitizeTrimsWhitespace() {
        #expect(ChatUtils.sanitizeMessage("  Hello  ") == "Hello")
        #expect(ChatUtils.sanitizeMessage("\n\nTest\n\n") == "Test")
        #expect(ChatUtils.sanitizeMessage("  Привет мир  ") == "Привет мир")
    }

    // MARK: - Date Helpers

    @Test("isToday returns true for current date")
    func isTodayTrue() {
        #expect(ChatUtils.isToday(Date()) == true)
    }

    @Test("isToday returns false for yesterday")
    func isTodayFalseForYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(ChatUtils.isToday(yesterday) == false)
    }

    @Test("isYesterday returns true for yesterday's date")
    func isYesterdayTrue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(ChatUtils.isYesterday(yesterday) == true)
    }

    @Test("isYesterday returns false for today")
    func isYesterdayFalseForToday() {
        #expect(ChatUtils.isYesterday(Date()) == false)
    }

    @Test("formatMessageTime returns non-empty string")
    func formatTime() {
        let result = ChatUtils.formatMessageTime(Date())
        #expect(result.isEmpty == false)
    }

    @Test("formatMessageDate returns non-empty string")
    func formatDate() {
        let result = ChatUtils.formatMessageDate(Date())
        #expect(result.isEmpty == false)
    }

    // MARK: - ChatConstants

    @Test("ChatConstants have expected values")
    func constants() {
        #expect(ChatConstants.maxMessageLength == 2000)
        #expect(ChatConstants.maxMessagesInHistory == 100)
        #expect(ChatConstants.typingIndicatorDelay > 0)
        #expect(ChatConstants.messageAnimationDuration > 0)
    }
}
