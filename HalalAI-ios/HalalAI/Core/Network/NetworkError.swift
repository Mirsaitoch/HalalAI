//
//  NetworkError.swift
//  HalalAI
//
//  Единый тип ошибки сетевого слоя.
//

import Foundation

enum NetworkError: Error {
    /// Невалидный URL
    case invalidURL
    /// Ответ не является HTTPURLResponse
    case invalidResponse
    /// Статус-код не совпал с ожидаемым; data содержит тело ответа для доп. парсинга
    case serverError(statusCode: Int, data: Data)
    /// Ошибка декодирования JSON
    case decodingError(Error)
    /// Ошибка URLSession (таймаут, нет сети и т.д.)
    case unknown(Error)
}
