//
//  IngredientMatcherTests.swift
//  HalalAITests
//

import Testing
@testable import HalalAI

struct IngredientMatcherTests {
    let sut = IngredientMatcher()

    // MARK: - Fixtures

    static let halalIngredient = Ingredient(
        eCode: "E100",
        status: .halal,
        nameRu: "Куркумин",
        nameEn: "Curcumin"
    )

    static let haramIngredient = Ingredient(
        eCode: "E120",
        status: .haram,
        nameRu: "Кармин",
        nameEn: "Carmine"
    )

    static let mushboohIngredient = Ingredient(
        eCode: "E471",
        status: .mushbooh,
        nameRu: "Моно- и диглицериды жирных кислот",
        nameEn: "Mono- and diglycerides of fatty acids"
    )

    static let noECodeIngredient = Ingredient(
        eCode: nil,
        status: .haram,
        nameRu: "Желатин свиной",
        nameEn: "Pork gelatin"
    )

    static let allIngredients = [
        halalIngredient,
        haramIngredient,
        mushboohIngredient,
        noECodeIngredient
    ]

    // MARK: - E-Code Detection

    @Test("Detects E-code in text and matches to ingredient")
    func eCodeDetection() {
        let result = sut.analyze(
            text: "Состав: сахар, E120, вода",
            ingredients: Self.allIngredients
        )
        #expect(result.ingredients.count == 1)
        #expect(result.ingredients.first?.status == .haram)
        #expect(result.overallStatus == .haram)
    }

    @Test("Detects multiple E-codes")
    func multipleECodes() {
        let result = sut.analyze(
            text: "E100, E120, E471",
            ingredients: Self.allIngredients
        )
        #expect(result.ingredients.count == 3)
        #expect(result.haramIngredients.count == 1)
        #expect(result.mushboohIngredients.count == 1)
    }

    @Test("E-code matching is case insensitive")
    func eCodeCaseInsensitive() {
        let result = sut.analyze(
            text: "e100, e120",
            ingredients: Self.allIngredients
        )
        #expect(result.ingredients.count == 2)
    }

    @Test("Unknown E-code is ignored")
    func unknownECodeIgnored() {
        let result = sut.analyze(
            text: "E999",
            ingredients: Self.allIngredients
        )
        #expect(result.ingredients.isEmpty)
    }

    // MARK: - Name Matching

    @Test("Matches ingredient by Russian name")
    func matchByRussianName() {
        let result = sut.analyze(
            text: "Состав: сахар, желатин свиной, вода",
            ingredients: Self.allIngredients
        )
        let haramNames = result.haramIngredients.map { $0.name }
        #expect(haramNames.contains("Желатин свиной"), "Should detect 'Желатин свиной' in text")
    }

    @Test("Matches ingredient by English name")
    func matchByEnglishName() {
        let result = sut.analyze(
            text: "Ingredients: sugar, carmine, water",
            ingredients: Self.allIngredients
        )
        #expect(result.haramIngredients.isEmpty == false, "Should detect 'Carmine' in text")
    }

    // MARK: - Overall Status

    @Test("Overall status is halal when all detected ingredients are halal",
          arguments: [
            "E100",
            "Куркумин"
          ])
    func overallStatusHalal(text: String) {
        let result = sut.analyze(text: text, ingredients: Self.allIngredients)
        #expect(result.overallStatus == .halal)
    }

    @Test("Overall status is haram when any haram ingredient detected")
    func overallStatusHaram() {
        let result = sut.analyze(
            text: "E100, E120",
            ingredients: Self.allIngredients
        )
        #expect(result.overallStatus == .haram)
    }

    @Test("Overall status is mushbooh when no haram but mushbooh present")
    func overallStatusMushbooh() {
        let result = sut.analyze(
            text: "E100, E471",
            ingredients: Self.allIngredients
        )
        #expect(result.overallStatus == .mushbooh)
    }

    @Test("Overall status is unknown when no ingredients detected")
    func overallStatusUnknown() {
        let result = sut.analyze(
            text: "просто текст без ингредиентов",
            ingredients: Self.allIngredients
        )
        #expect(result.overallStatus == .unknown)
    }

    // MARK: - Edge Cases

    @Test("Empty text returns no ingredients")
    func emptyText() {
        let result = sut.analyze(text: "", ingredients: Self.allIngredients)
        #expect(result.ingredients.isEmpty)
        #expect(result.overallStatus == .unknown)
    }

    @Test("Empty ingredient database returns no matches")
    func emptyDatabase() {
        let result = sut.analyze(text: "E100, E120", ingredients: [])
        #expect(result.ingredients.isEmpty)
    }

    @Test("Does not duplicate ingredient found by both E-code and name")
    func noDuplicatesForSameIngredient() {
        let result = sut.analyze(
            text: "E120 кармин",
            ingredients: Self.allIngredients
        )
        let e120Count = result.ingredients.filter {
            $0.matchedIngredient?.eCode == "E120"
        }.count
        #expect(e120Count == 1, "E120 should appear only once even if matched by both E-code and name")
    }

    // MARK: - Haram Priority

    @Test("Haram takes priority over mushbooh in overall status")
    func haramPriorityOverMushbooh() {
        let result = sut.analyze(
            text: "E120, E471, E100",
            ingredients: Self.allIngredients
        )
        #expect(result.overallStatus == .haram)
        #expect(result.haramIngredients.isEmpty == false)
        #expect(result.mushboohIngredients.isEmpty == false)
    }
}
