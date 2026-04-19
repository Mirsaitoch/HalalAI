//
//  APIConfiguration.swift
//  HalalAI
//
//  Единая точка конфигурации URL бекенда.
//

import Foundation

enum APIConfiguration {
    static var backendURL: String {
        #if DEBUG
        return "http://localhost:8080"
        #else
        // TODO: Заменить на production URL
        return "https://your-production-url.com"
        #endif
    }
}
