//
//  IngredientModelsTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct IngredientModelsTests {

    // MARK: - IngredientStatus

    @Test("IngredientStatus raw values match expected strings",
          arguments: [
            (IngredientStatus.halal, "halal"),
            (IngredientStatus.haram, "haram"),
            (IngredientStatus.mushbooh, "mushbooh"),
            (IngredientStatus.unknown, "unknown")
          ])
    func statusRawValues(status: IngredientStatus, expected: String) {
        #expect(status.rawValue == expected)
    }

    @Test("IngredientStatus display names are localized in Russian",
          arguments: [
            (IngredientStatus.halal, "Халяль"),
            (IngredientStatus.haram, "Харам"),
            (IngredientStatus.mushbooh, "Сомнительно"),
            (IngredientStatus.unknown, "Неизвестно")
          ])
    func statusDisplayNames(status: IngredientStatus, expected: String) {
        #expect(status.displayName == expected)
    }

    // MARK: - Ingredient Codable

    @Test("Ingredient encodes and decodes correctly")
    func ingredientCodable() throws {
        let original = Ingredient(
            eCode: "E100",
            status: .halal,
            nameRu: "Куркумин",
            nameEn: "Curcumin",
            note: "Натуральный краситель"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Ingredient.self, from: data)

        #expect(decoded.eCode == "E100")
        #expect(decoded.status == .halal)
        #expect(decoded.nameRu == "Куркумин")
        #expect(decoded.nameEn == "Curcumin")
        #expect(decoded.note == "Натуральный краситель")
    }

    @Test("Ingredient decodes nil eCode when empty string in JSON")
    func ingredientDecodesEmptyECode() throws {
        let json = """
        {"e_code": "", "status": "halal", "name_ru": "Тест", "name_en": "Test"}
        """
        let decoded = try JSONDecoder().decode(Ingredient.self, from: Data(json.utf8))
        #expect(decoded.eCode == nil, "Empty e_code should decode as nil")
    }

    @Test("Ingredient decodes nil note when empty string in JSON")
    func ingredientDecodesEmptyNote() throws {
        let json = """
        {"e_code": "E100", "status": "halal", "name_ru": "Тест", "name_en": "Test", "note": ""}
        """
        let decoded = try JSONDecoder().decode(Ingredient.self, from: Data(json.utf8))
        #expect(decoded.note == nil, "Empty note should decode as nil")
    }

    @Test("Ingredient decodes unknown status from invalid raw value")
    func ingredientDecodesUnknownStatus() throws {
        let json = """
        {"e_code": "E999", "status": "invalid_status", "name_ru": "Тест", "name_en": "Test"}
        """
        let decoded = try JSONDecoder().decode(Ingredient.self, from: Data(json.utf8))
        #expect(decoded.status == .unknown)
    }

    // MARK: - ProductAnalysis

    @Test("ProductAnalysis.isHalal returns true only when all conditions met")
    func productAnalysisIsHalal() {
        let halalAnalysis = ProductAnalysis(
            ingredients: [DetectedIngredient(name: "E100", matchedIngredient: Ingredient(
                eCode: "E100", status: .halal, nameRu: "Куркумин", nameEn: "Curcumin"
            ))],
            overallStatus: .halal,
            haramIngredients: [],
            mushboohIngredients: []
        )
        #expect(halalAnalysis.isHalal == true)
    }

    @Test("ProductAnalysis.isHalal returns false when haram ingredients present")
    func productAnalysisNotHalalWithHaram() {
        let detected = DetectedIngredient(name: "E120", matchedIngredient: Ingredient(
            eCode: "E120", status: .haram, nameRu: "Кармин", nameEn: "Carmine"
        ))
        let analysis = ProductAnalysis(
            ingredients: [detected],
            overallStatus: .haram,
            haramIngredients: [detected],
            mushboohIngredients: []
        )
        #expect(analysis.isHalal == false)
    }

    // MARK: - DetectedIngredient

    @Test("DetectedIngredient without matched ingredient has unknown status")
    func detectedIngredientUnknownStatus() {
        let detected = DetectedIngredient(name: "Unknown stuff")
        #expect(detected.status == .unknown)
        #expect(detected.matchedIngredient == nil)
    }

    @Test("DetectedIngredient inherits status from matched ingredient")
    func detectedIngredientInheritsStatus() {
        let ingredient = Ingredient(
            eCode: "E120", status: .haram, nameRu: "Кармин", nameEn: "Carmine"
        )
        let detected = DetectedIngredient(name: "E120", matchedIngredient: ingredient)
        #expect(detected.status == .haram)
    }
}
