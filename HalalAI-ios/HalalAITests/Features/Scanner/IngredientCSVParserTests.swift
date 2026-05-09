//
//  IngredientCSVParserTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct IngredientCSVParserTests {
    let sut = IngredientCSVParser()

    // MARK: - Valid CSV Parsing

    @Test("Parses valid CSV with header and data rows")
    func parseValidCSV() throws {
        let csv = """
        e_code,status,name_ru,name_en,note
        E100,halal,Куркумин,Curcumin,Натуральный краситель
        E120,haram,Кармин,Carmine,Из насекомых
        """
        let ingredients = try sut.parse(csvString: csv)
        #expect(ingredients.count == 2)
        #expect(ingredients[0].eCode == "E100")
        #expect(ingredients[0].status == .halal)
        #expect(ingredients[0].nameRu == "Куркумин")
        #expect(ingredients[0].nameEn == "Curcumin")
        #expect(ingredients[0].note == "Натуральный краситель")
        #expect(ingredients[1].eCode == "E120")
        #expect(ingredients[1].status == .haram)
    }

    @Test("Parses CSV with empty e_code as nil")
    func emptyECode() throws {
        let csv = """
        e_code,status,name_ru,name_en,note
        ,haram,Желатин свиной,Pork gelatin,
        """
        let ingredients = try sut.parse(csvString: csv)
        #expect(ingredients.count == 1)
        #expect(ingredients[0].eCode == nil)
    }

    @Test("Parses CSV with empty note as nil")
    func emptyNote() throws {
        let csv = """
        e_code,status,name_ru,name_en,note
        E100,halal,Куркумин,Curcumin,
        """
        let ingredients = try sut.parse(csvString: csv)
        #expect(ingredients.count == 1)
        #expect(ingredients[0].note == nil)
    }

    @Test("Parses CSV with quoted fields containing commas")
    func quotedFieldsWithCommas() throws {
        let csv = """
        e_code,status,name_ru,name_en,note
        E471,mushbooh,"Моно- и диглицериды, жирных кислот",Mono diglycerides,"Может быть, растительного происхождения"
        """
        let ingredients = try sut.parse(csvString: csv)
        #expect(ingredients.count == 1)
        #expect(ingredients[0].nameRu.contains("Моно-"))
    }

    @Test("Skips rows with invalid status")
    func skipsInvalidStatus() throws {
        let csv = """
        e_code,status,name_ru,name_en,note
        E100,halal,Куркумин,Curcumin,
        E999,invalid_status,Тест,Test,
        E120,haram,Кармин,Carmine,
        """
        let ingredients = try sut.parse(csvString: csv)
        #expect(ingredients.count == 2, "Should skip row with invalid status")
    }

    @Test("Skips rows with fewer than 4 columns")
    func skipsShortRows() throws {
        let csv = """
        e_code,status,name_ru,name_en,note
        E100,halal,Куркумин,Curcumin,
        short,row
        E120,haram,Кармин,Carmine,
        """
        let ingredients = try sut.parse(csvString: csv)
        #expect(ingredients.count == 2)
    }

    // MARK: - Error Cases

    @Test("Throws invalidFormat for header-only CSV")
    func headerOnlyThrows() {
        let csv = "e_code,status,name_ru,name_en,note"
        #expect(throws: IngredientServiceError.self) {
            try sut.parse(csvString: csv)
        }
    }

    @Test("Throws invalidFormat for empty string")
    func emptyStringThrows() {
        #expect(throws: IngredientServiceError.self) {
            try sut.parse(csvString: "")
        }
    }

    // MARK: - Multiple Statuses

    @Test("Parses all ingredient statuses",
          arguments: [
            ("halal", IngredientStatus.halal),
            ("haram", IngredientStatus.haram),
            ("mushbooh", IngredientStatus.mushbooh),
            ("unknown", IngredientStatus.unknown)
          ])
    func allStatuses(rawValue: String, expected: IngredientStatus) throws {
        let csv = """
        e_code,status,name_ru,name_en,note
        E100,\(rawValue),Тест,Test,
        """
        let ingredients = try sut.parse(csvString: csv)
        let status = try #require(ingredients.first?.status)
        #expect(status == expected)
    }
}
