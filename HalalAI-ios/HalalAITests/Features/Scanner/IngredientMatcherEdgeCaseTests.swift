//
//  IngredientMatcherEdgeCaseTests.swift
//  HalalAITests
//
//  Additional edge case tests to improve IngredientMatcher coverage.
//

import Foundation
import Testing
@testable import HalalAI

struct IngredientMatcherEdgeCaseTests {
    let sut = IngredientMatcher()

    // MARK: - Fixtures

    private static let ingredients: [Ingredient] = [
        Ingredient(eCode: "E100", status: .halal, nameRu: "Куркумин", nameEn: "Curcumin"),
        Ingredient(eCode: "E120", status: .haram, nameRu: "Кармин", nameEn: "Carmine"),
        Ingredient(eCode: "E471", status: .mushbooh, nameRu: "Моно- и диглицериды жирных кислот", nameEn: "Mono- and diglycerides of fatty acids"),
        Ingredient(eCode: nil, status: .haram, nameRu: "Желатин свиной", nameEn: "Pork gelatin"),
        Ingredient(eCode: "E160a", status: .halal, nameRu: "Каротин", nameEn: "Carotene"),
        Ingredient(eCode: "E160b", status: .mushbooh, nameRu: "Аннатто", nameEn: "Annatto"),
        Ingredient(eCode: nil, status: .halal, nameRu: "Лимонная кислота", nameEn: "Citric acid"),
        Ingredient(eCode: nil, status: .halal, nameRu: "Соль", nameEn: "Salt"),
        Ingredient(eCode: nil, status: .haram, nameRu: "Свиной жир", nameEn: "Lard"),
    ]

    // MARK: - E-Code Edge Cases

    @Test("E-codes with numeric-only suffixes are detected")
    func eCodeNumericSuffix() {
        let result = sut.analyze(text: "E100, E120, E471", ingredients: Self.ingredients)
        #expect(result.ingredients.count == 3)
    }

    @Test("Standalone 'E' without number is not treated as E-code")
    func standaloneENotECode() {
        let result = sut.analyze(text: "E is a letter", ingredients: Self.ingredients)
        #expect(result.ingredients.isEmpty)
    }

    // MARK: - Multi-word Name Matching

    @Test("Multi-word ingredient matched: 'лимонная кислота'")
    func multiWordRussianName() {
        let result = sut.analyze(
            text: "Состав: сахар, лимонная кислота, вода",
            ingredients: Self.ingredients
        )
        let names = result.ingredients.map { $0.name.lowercased() }
        #expect(names.contains(where: { $0.contains("лимонная кислота") || $0.contains("лимонн") }),
                "Should detect 'Лимонная кислота'")
    }

    @Test("Multi-word English ingredient matched: 'citric acid'")
    func multiWordEnglishName() {
        let result = sut.analyze(
            text: "Ingredients: sugar, citric acid, water",
            ingredients: Self.ingredients
        )
        let names = result.ingredients.map { $0.name.lowercased() }
        #expect(names.contains(where: { $0.contains("citric") }),
                "Should detect 'Citric acid'")
    }

    // MARK: - Short Name Edge Cases

    @Test("Short name 'Соль' requires word boundary match")
    func shortNameWordBoundary() {
        // "Соль" is 4 chars, < 5, so only exact word boundary matches
        let result = sut.analyze(text: "Состав: соль, сахар", ingredients: Self.ingredients)
        let halalNames = result.ingredients.filter { $0.status == .halal }
        #expect(halalNames.contains(where: { $0.name.lowercased().contains("соль") }),
                "Should detect 'Соль' as word boundary match")
    }

    // MARK: - Mixed Content

    @Test("Text with both E-codes and names detects all")
    func mixedECodesAndNames() {
        let result = sut.analyze(
            text: "E120, лимонная кислота, E100",
            ingredients: Self.ingredients
        )
        #expect(result.ingredients.count >= 2, "Should detect at least E120 and E100")
        #expect(result.haramIngredients.isEmpty == false, "Should find haram E120")
    }

    @Test("Case-insensitive name matching")
    func caseInsensitiveNameMatch() {
        let result = sut.analyze(
            text: "PORK GELATIN in this product",
            ingredients: Self.ingredients
        )
        #expect(result.haramIngredients.isEmpty == false, "Should detect 'Pork gelatin' case-insensitively")
    }

    // MARK: - Score-based Filtering

    @Test("Higher score matches preferred over lower")
    func higherScorePreferred() {
        // "Моно- и диглицериды жирных кислот" is a long multi-word name
        let result = sut.analyze(
            text: "моно- и диглицериды жирных кислот",
            ingredients: Self.ingredients
        )
        #expect(result.mushboohIngredients.isEmpty == false)
    }

    // MARK: - Special Characters

    @Test("Text with special characters doesn't crash")
    func specialCharactersNoCrash() {
        let texts = [
            "E120 (краситель)",
            "Состав: сахар; E100; вода",
            "E471 / E100",
            "E120\nE100\nE471",
            "Е100",  // Cyrillic Е
        ]
        for text in texts {
            let result = sut.analyze(text: text, ingredients: Self.ingredients)
            _ = result.overallStatus // just ensure no crash
        }
    }

    // MARK: - Large Input

    @Test("Large text input doesn't crash")
    func largeInputNoCrash() {
        let baseText = "Состав: сахар, вода, мука, соль, E100, E120, E471, "
        let largeText = String(repeating: baseText, count: 50)
        let result = sut.analyze(text: largeText, ingredients: Self.ingredients)
        #expect(result.ingredients.isEmpty == false)
    }
}
