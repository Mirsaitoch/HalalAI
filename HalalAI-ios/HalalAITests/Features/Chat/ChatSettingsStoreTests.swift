//
//  ChatSettingsStoreTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct ChatSettingsStoreTests {

    // MARK: - maxTokens Clamping

    @Test("maxTokens clamps to minimum 16")
    func maxTokensClampMin() {
        let store = ChatSettingsStore()
        store.maxTokens = 5
        #expect(store.maxTokens == 16, "maxTokens below 16 should be clamped to 16")
    }

    @Test("maxTokens clamps to maximum 6144")
    func maxTokensClampMax() {
        let store = ChatSettingsStore()
        store.maxTokens = 10000
        #expect(store.maxTokens == 6144, "maxTokens above 6144 should be clamped to 6144")
    }

    @Test("maxTokens within range stays unchanged",
          arguments: [16, 100, 2048, 4096, 6144])
    func maxTokensWithinRange(value: Int) {
        let store = ChatSettingsStore()
        store.maxTokens = value
        #expect(store.maxTokens == value)
    }

    // MARK: - temperature Clamping

    @Test("temperature clamps to minimum 0.0")
    func temperatureClampMin() {
        let store = ChatSettingsStore()
        store.temperature = -1.0
        #expect(store.temperature == 0.0, "Negative temperature should be clamped to 0.0")
    }

    @Test("temperature clamps to maximum 2.0")
    func temperatureClampMax() {
        let store = ChatSettingsStore()
        store.temperature = 5.0
        #expect(store.temperature == 2.0, "Temperature above 2.0 should be clamped to 2.0")
    }

    @Test("temperature within range stays unchanged")
    func temperatureWithinRange() {
        let store = ChatSettingsStore()
        store.temperature = 1.5
        #expect(store.temperature == 1.5)
    }

    // MARK: - Default Values

    @Test("Default maxTokens is 2048 when no saved value")
    func defaultMaxTokens() {
        // Clean up
        let key = "HalalAI.maxTokens"
        UserDefaults.standard.removeObject(forKey: key)
        let store = ChatSettingsStore()
        #expect(store.maxTokens == 2048)
    }

    @Test("Default temperature is 0.7 when no saved value")
    func defaultTemperature() {
        let key = "HalalAI.temperature"
        UserDefaults.standard.removeObject(forKey: key)
        let store = ChatSettingsStore()
        #expect(store.temperature == 0.7)
    }

    @Test("Default useRag is true when no saved value")
    func defaultUseRag() {
        let key = "HalalAI.useRag"
        UserDefaults.standard.removeObject(forKey: key)
        let store = ChatSettingsStore()
        #expect(store.useRag == true)
    }
}
