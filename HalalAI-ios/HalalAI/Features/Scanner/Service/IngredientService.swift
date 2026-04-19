//
//  IngredientService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

protocol IngredientService {
    func loadIngredients() async throws -> [Ingredient]
    func analyzeText(_ text: String) async -> ProductAnalysis
}

@MainActor
final class IngredientServiceImpl: IngredientService {
    private var ingredients: [Ingredient] = []
    private var ingredientsLoaded = false

    private let parser = IngredientCSVParser()
    private let matcher = IngredientMatcher()

    func loadIngredients() async throws -> [Ingredient] {
        if ingredientsLoaded {
            return ingredients
        }

        ingredients = try parser.parseFromBundle()
        ingredientsLoaded = true
        return ingredients
    }

    func analyzeText(_ text: String) async -> ProductAnalysis {
        _ = try? await loadIngredients()
        return matcher.analyze(text: text, ingredients: ingredients)
    }
}

enum IngredientServiceError: LocalizedError {
    case fileNotFound
    case invalidFormat
    case loadingFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Файл с ингредиентами не найден"
        case .invalidFormat:
            return "Неверный формат файла"
        case .loadingFailed:
            return "Ошибка загрузки данных"
        }
    }
}
