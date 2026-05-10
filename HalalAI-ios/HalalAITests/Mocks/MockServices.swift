//
//  MockServices.swift
//  HalalAITests
//

import Foundation
import CoreLocation
@testable import HalalAI

// MARK: - MockAuthService

@MainActor
final class MockAuthService: AuthService {
    var isLoading = false
    var errorMessage: String?

    var loginResult: Result<AuthResponse, Error> = .success(
        AuthResponse(token: "mock-token", type: "Bearer", userId: 1, email: "mock@test.com")
    )
    var registerResult: Result<AuthResponse, Error> = .success(
        AuthResponse(token: "mock-token", type: "Bearer", userId: 1, email: "mock@test.com")
    )
    var refreshResult: Result<AuthResponse, Error> = .success(
        AuthResponse(token: "new-token", type: "Bearer", userId: 1, email: "mock@test.com")
    )

    var loginCallCount = 0
    var registerCallCount = 0

    func login(email: String, password: String) async throws -> AuthResponse {
        loginCallCount += 1
        return try loginResult.get()
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        registerCallCount += 1
        return try registerResult.get()
    }

    func refreshToken(_ oldToken: String) async throws -> AuthResponse {
        return try refreshResult.get()
    }
}

// MARK: - MockAuthManager

@MainActor
final class MockAuthManager: AuthManager {
    var authState: AuthState = .unauthenticated
    var currentUser: AuthResponse?
    var errorMessage: String?
    var authToken: String?

    var isAuthenticated: Bool { authState == .authenticated && currentUser != nil }
    var isGuest: Bool { authState == .guest }

    var saveAuthCallCount = 0
    var logoutCallCount = 0

    func saveAuth(_ response: AuthResponse) {
        saveAuthCallCount += 1
        currentUser = response
        authToken = response.token
        authState = .authenticated
    }

    func logout() {
        logoutCallCount += 1
        currentUser = nil
        authToken = nil
        authState = .unauthenticated
    }

    func continueAsGuest() {
        authState = .guest
    }

    func refreshToken() async throws {
        // no-op in mock
    }
}

// MARK: - MockChatService

@MainActor
final class MockChatService: ChatService {
    var messages: [ChatMessage] = []
    var chatState: ChatState = .idle
    var connectionState: ConnectionState = .connected
    var userApiKey: String = ""
    var remoteModel: String = ""
    var maxTokens: Int = 2048
    var temperature: Double = 0.7
    var useRag: Bool = true
    var availableModels: [String] = []
    var defaultRemoteModel: String = ""

    var sendMessageCallCount = 0
    var lastSentMessage: String?
    var clearChatCallCount = 0

    func loadModels() async {}

    func sendMessage(_ text: String) {
        sendMessageCallCount += 1
        lastSentMessage = text
    }

    func retryLastMessage() {}
    func clearChat() {
        clearChatCallCount += 1
        messages.removeAll()
    }
}

// MARK: - MockIngredientService

@MainActor
final class MockIngredientService: IngredientService {
    var ingredients: [Ingredient] = []
    var analyzeResult = ProductAnalysis(
        ingredients: [],
        overallStatus: .unknown,
        haramIngredients: [],
        mushboohIngredients: []
    )
    var analyzeCallCount = 0

    func loadIngredients() async throws -> [Ingredient] {
        return ingredients
    }

    func analyzeText(_ text: String) async -> ProductAnalysis {
        analyzeCallCount += 1
        return analyzeResult
    }
}

// MARK: - MockQuranStorageService

@MainActor
final class MockQuranStorageService: QuranStorageService {
    var suras: [Sura] = []
    var lastReadSuraIndex: Int?
    var lastReadVerseNumber: Int?
    var loadCallCount = 0
    var saveProgressCallCount = 0
    var savedSuraIndex: Int?
    var savedVerseNumber: Int?
    var shouldThrow = false

    func loadQuranFromBundle() throws {
        loadCallCount += 1
        if shouldThrow {
            throw QuranError.fileNotFound
        }
    }

    func saveProgress(suraIndex: Int, verseNumber: Int) {
        saveProgressCallCount += 1
        savedSuraIndex = suraIndex
        savedVerseNumber = verseNumber
    }

    func clearProgress() {
        lastReadSuraIndex = nil
        lastReadVerseNumber = nil
    }
}

// MARK: - MockLocationService

@MainActor
final class MockLocationService: LocationService {
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    var requestLocationCallCount = 0

    func requestLocation() {
        requestLocationCallCount += 1
    }
}

// MARK: - MockNetworkClient

final class MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    var sendHandler: ((any APIRequest) async throws -> Any)?
    var sendRawHandler: ((any APIRequest) async throws -> (Data, HTTPURLResponse))?

    var sendCallCount = 0
    var sendRawCallCount = 0

    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        sendCallCount += 1
        if let handler = sendHandler {
            let result = try await handler(request)
            return result as! R.Response
        }
        fatalError("MockNetworkClient.send not configured")
    }

    func sendRaw<R: APIRequest>(_ request: R) async throws -> (Data, HTTPURLResponse) {
        sendRawCallCount += 1
        if let handler = sendRawHandler {
            return try await handler(request)
        }
        fatalError("MockNetworkClient.sendRaw not configured")
    }
}

// MARK: - MockHalalPlacesService

final class MockHalalPlacesService: HalalPlacesService {
    var searchResult: Result<[HalalPlace], Error> = .success([])
    var searchCallCount = 0
    var lastSearchCoordinate: CLLocationCoordinate2D?

    func searchNearby(coordinate: CLLocationCoordinate2D) async throws -> [HalalPlace] {
        searchCallCount += 1
        lastSearchCoordinate = coordinate
        return try searchResult.get()
    }
}

// MARK: - MockVerseService

@MainActor
final class MockVerseService: VerseService {
    var verseOfTheDay: Verse?
    var fetchCallCount = 0
    var shouldThrow = false

    func fetchVerseOfTheDay() async throws {
        fetchCallCount += 1
        if shouldThrow {
            throw NSError(domain: "test", code: 1)
        }
    }
}

// MARK: - MockPrayerTimeService

final class MockPrayerNotificationService: PrayerNotificationService {
    func requestAuthorization() async -> Bool { true }
    func scheduleNotifications(settings: PrayerSettings, location: CLLocation) async {}
    func rescheduleIfNeeded(settings: PrayerSettings, location: CLLocation?) async {}
    func cancelAllPrayerNotifications() async {}
    func sendTestNotification() async {}
}

final class MockPrayerTimeService: PrayerTimeService {
    var calculateResult: DailyPrayerTimes?
    var nextPrayerResult: (Prayer, Date)?

    func calculateTimes(
        for date: Date,
        location: CLLocation,
        settings: PrayerSettings
    ) -> DailyPrayerTimes? {
        return calculateResult
    }

    func nextPrayer(from times: DailyPrayerTimes) -> (Prayer, Date)? {
        return nextPrayerResult
    }
}
