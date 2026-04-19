//
//  Endpoint.swift
//  HalalAI
//
//  Типизированный enum со всеми API-маршрутами приложения.
//

import Foundation

enum Endpoint {
    // Auth
    case login
    case register
    case refreshToken

    // Chat
    case chat
    case models

    // Verse
    case verseOfTheDay

    var path: String {
        switch self {
        case .login:        "/api/auth/login"
        case .register:     "/api/auth/register"
        case .refreshToken: "/api/auth/refresh"
        case .chat:         "/api/chat"
        case .models:       "/api/models"
        case .verseOfTheDay: "/api/verse-of-the-day"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .refreshToken, .chat: .post
        case .models, .verseOfTheDay:                 .get
        }
    }
}
