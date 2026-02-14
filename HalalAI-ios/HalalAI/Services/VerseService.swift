//
//  VerseService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 09.01.2026.
//

import Foundation

protocol VerseService {
    var verseOfTheDay: Verse? { get set }
    func fetchVerseOfTheDay() async throws
}

@Observable
final class VerseServiceImpl: VerseService {
    var verseOfTheDay: Verse?
    
    private let backendURL: String = {
        #if DEBUG
        return "http://localhost:8080"
        #else
        // TODO: Заменить на production URL
        return "https://your-production-url.com"
        #endif
    }()
    
    private var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    
    func fetchVerseOfTheDay() async throws  {
        guard let url = URL(string: backendURL + "/api/verse-of-the-day") else {
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError("Неверный ответ от сервера")
            }
            
            if httpResponse.statusCode == 200 {
                verseOfTheDay = try JSONDecoder().decode(Verse.self, from: data)
            }
        } catch let error {
            throw error
        }
    }
}
