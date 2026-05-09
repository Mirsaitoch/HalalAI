//
//  QuranErrorTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

struct QuranErrorTests {

    @Test("QuranError.fileNotFound has correct description")
    func fileNotFound() {
        let error = QuranError.fileNotFound
        #expect(error.errorDescription == "Файл Корана не найден в приложении.")
    }

    @Test("QuranError.encodingError has correct description")
    func encodingError() {
        let error = QuranError.encodingError
        #expect(error.errorDescription == "Ошибка кодировки файла.")
    }

    @Test("QuranError.emptyFile has correct description")
    func emptyFile() {
        let error = QuranError.emptyFile
        #expect(error.errorDescription == "Файл Корана пуст.")
    }
}

struct IngredientServiceErrorTests {

    @Test("IngredientServiceError.fileNotFound has correct description")
    func fileNotFound() {
        let error = IngredientServiceError.fileNotFound
        #expect(error.errorDescription == "Файл с ингредиентами не найден")
    }

    @Test("IngredientServiceError.invalidFormat has correct description")
    func invalidFormat() {
        let error = IngredientServiceError.invalidFormat
        #expect(error.errorDescription == "Неверный формат файла")
    }

    @Test("IngredientServiceError.loadingFailed has correct description")
    func loadingFailed() {
        let error = IngredientServiceError.loadingFailed
        #expect(error.errorDescription == "Ошибка загрузки данных")
    }
}
