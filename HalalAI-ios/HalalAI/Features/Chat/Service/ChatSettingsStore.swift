//
//  ChatSettingsStore.swift
//  HalalAI
//
//  Персистенция настроек чата (API key, модель, токены, temperature, RAG).
//

import Foundation

@MainActor
@Observable
final class ChatSettingsStore {
    var userApiKey: String {
        didSet { UserDefaults.standard.set(userApiKey, forKey: Keys.apiKey) }
    }
    var remoteModel: String {
        didSet { UserDefaults.standard.set(remoteModel, forKey: Keys.remoteModel) }
    }
    var maxTokens: Int {
        didSet {
            let clamped = max(16, min(maxTokens, 6144))
            if clamped != maxTokens {
                maxTokens = clamped
                return
            }
            UserDefaults.standard.set(maxTokens, forKey: Keys.maxTokens)
        }
    }
    var temperature: Double {
        didSet {
            let clamped = max(0.0, min(temperature, 2.0))
            if clamped != temperature {
                temperature = clamped
                return
            }
            UserDefaults.standard.set(temperature, forKey: Keys.temperature)
        }
    }
    var useRag: Bool {
        didSet { UserDefaults.standard.set(useRag, forKey: Keys.useRag) }
    }

    init() {
        self.userApiKey = UserDefaults.standard.string(forKey: Keys.apiKey) ?? ""
        self.remoteModel = UserDefaults.standard.string(forKey: Keys.remoteModel) ?? ""
        let savedMax = UserDefaults.standard.integer(forKey: Keys.maxTokens)
        self.maxTokens = savedMax == 0 ? 2048 : savedMax
        let savedTemp = UserDefaults.standard.double(forKey: Keys.temperature)
        self.temperature = savedTemp == 0 ? 0.7 : savedTemp
        self.useRag = UserDefaults.standard.object(forKey: Keys.useRag) as? Bool ?? true
    }

    private enum Keys {
        static let apiKey = "HalalAI.userApiKey"
        static let remoteModel = "HalalAI.remoteModel"
        static let maxTokens = "HalalAI.maxTokens"
        static let temperature = "HalalAI.temperature"
        static let useRag = "HalalAI.useRag"
    }
}
