//
//  LanguageStore.swift
//  HalalAI
//

import Foundation

@MainActor
@Observable
final class LanguageStore {
    private static let defaultsKey = "HalalAI.appLanguage"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.defaultsKey)
            _bundle = nil
        }
    }

    private var _bundle: Bundle?

    private var bundle: Bundle {
        if let cached = _bundle { return cached }
        let b = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
            .flatMap { Bundle(path: $0) } ?? Bundle.main
        _bundle = b
        return b
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.defaultsKey)
        currentLanguage = AppLanguage(rawValue: saved ?? "") ?? .russian
    }

    func t(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
