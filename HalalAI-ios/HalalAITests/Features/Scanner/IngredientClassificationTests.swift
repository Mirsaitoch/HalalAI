//
//  IngredientClassificationTests.swift
//  HalalAITests
//
//  Тесты корректности классификации ингредиентов (раздел 4.4.2 диплома).
//

import Testing
@testable import HalalAI

/// Проверяет, что система корректно присваивает статус каждому ингредиенту
/// и соблюдает приоритет: haram > mushbooh > halal > unknown.
struct IngredientClassificationTests {
    let sut = IngredientMatcher()

    // MARK: - Fixtures

    private static let db: [Ingredient] = [
        Ingredient(eCode: "E100", status: .halal,    nameRu: "Куркумин",                          nameEn: "Curcumin"),
        Ingredient(eCode: "E120", status: .haram,    nameRu: "Кармин",                            nameEn: "Carmine"),
        Ingredient(eCode: "E471", status: .mushbooh, nameRu: "Моно- и диглицериды жирных кислот", nameEn: "Mono- and diglycerides of fatty acids"),
        Ingredient(eCode: nil,    status: .haram,    nameRu: "Желатин свиной",                    nameEn: "Pork gelatin"),
        Ingredient(eCode: nil,    status: .mushbooh, nameRu: "Натуральный ароматизатор",          nameEn: "Natural flavour"),
        Ingredient(eCode: nil,    status: .halal,    nameRu: "Лимонная кислота",                  nameEn: "Citric acid"),
    ]

    // MARK: - Классификация по E-коду

    @Test("E-код халяльного ингредиента классифицируется как халяль")
    func eCodeHalal() {
        let result = sut.analyze(text: "E100", ingredients: Self.db)
        #expect(result.ingredients.first?.status == .halal)
    }

    @Test("E-код харамного ингредиента классифицируется как харам")
    func eCodeHaram() {
        let result = sut.analyze(text: "E120", ingredients: Self.db)
        #expect(result.ingredients.first?.status == .haram)
    }

    @Test("E-код сомнительного ингредиента классифицируется как мушбух")
    func eCodeMushbooh() {
        let result = sut.analyze(text: "E471", ingredients: Self.db)
        #expect(result.ingredients.first?.status == .mushbooh)
    }

    // MARK: - Классификация по названию (без E-кода)

    @Test("Харамный ингредиент без E-кода классифицируется по названию на русском")
    func nameOnlyHaramRussian() {
        let result = sut.analyze(text: "Состав: мука, желатин свиной, сахар", ingredients: Self.db)
        #expect(result.haramIngredients.isEmpty == false)
        #expect(result.overallStatus == .haram)
    }

    @Test("Харамный ингредиент без E-кода классифицируется по названию на английском")
    func nameOnlyHaramEnglish() {
        let result = sut.analyze(text: "Ingredients: flour, pork gelatin, sugar", ingredients: Self.db)
        #expect(result.haramIngredients.isEmpty == false)
        #expect(result.overallStatus == .haram)
    }

    @Test("Мушбух-ингредиент без E-кода классифицируется по названию")
    func nameOnlyMushbooh() {
        let result = sut.analyze(text: "натуральный ароматизатор", ingredients: Self.db)
        #expect(result.mushboohIngredients.isEmpty == false)
        #expect(result.overallStatus == .mushbooh)
    }

    @Test("Халяльный ингредиент без E-кода классифицируется по названию")
    func nameOnlyHalal() {
        let result = sut.analyze(text: "лимонная кислота", ingredients: Self.db)
        #expect(result.overallStatus == .halal)
    }

    // MARK: - Приоритет статусов

    @Test("Харам имеет приоритет над халялем: итог — харам")
    func priorityHaramOverHalal() {
        let result = sut.analyze(text: "E100 E120", ingredients: Self.db)
        #expect(result.overallStatus == .haram)
    }

    @Test("Харам имеет приоритет над мушбухом: итог — харам")
    func priorityHaramOverMushbooh() {
        let result = sut.analyze(text: "E120 E471", ingredients: Self.db)
        #expect(result.overallStatus == .haram)
    }

    @Test("Мушбух имеет приоритет над халялем при отсутствии харама: итог — мушбух")
    func priorityMushboohOverHalal() {
        let result = sut.analyze(text: "E100 E471", ingredients: Self.db)
        #expect(result.overallStatus == .mushbooh)
    }

    @Test("Полная цепочка приоритета: E100 + E471 + E120 → харам")
    func fullPriorityChain() {
        let result = sut.analyze(text: "E100 E471 E120", ingredients: Self.db)
        #expect(result.overallStatus == .haram)
        #expect(result.haramIngredients.count == 1)
        #expect(result.mushboohIngredients.count == 1)
        #expect(result.ingredients.count == 3)
    }

    // MARK: - Неизвестный ингредиент

    @Test("Ингредиент, отсутствующий в базе, получает статус unknown")
    func unknownIngredientNotInDatabase() {
        let result = sut.analyze(text: "E999", ingredients: Self.db)
        #expect(result.ingredients.isEmpty)
        #expect(result.overallStatus == .unknown)
    }

    @Test("Текст без ингредиентов из базы даёт статус unknown")
    func plainTextGivesUnknown() {
        let result = sut.analyze(text: "вода сахар мука соль", ingredients: [])
        #expect(result.overallStatus == .unknown)
    }
}
