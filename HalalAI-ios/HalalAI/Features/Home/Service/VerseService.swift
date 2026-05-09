//
//  VerseService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 09.01.2026.
//

import Foundation

@MainActor
protocol VerseService {
    var verseOfTheDay: Verse? { get set }
    func fetchVerseOfTheDay() async throws
}

@Observable
@MainActor
final class VerseServiceImpl: VerseService {
    var verseOfTheDay: Verse?

    private let networkClient: any NetworkClientProtocol

    init(networkClient: any NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }

    func fetchVerseOfTheDay() async throws {
        verseOfTheDay = try await networkClient.send(VerseOfTheDayAPIRequest())
    }
}

// MARK: - API

struct VerseOfTheDayAPIRequest: APIRequest {
    typealias Response = Verse

    let endpoint = Endpoint.verseOfTheDay
}
