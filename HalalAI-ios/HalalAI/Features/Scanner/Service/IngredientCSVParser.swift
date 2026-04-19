//
//  IngredientCSVParser.swift
//  HalalAI
//
//  Extracted from IngredientService.swift
//

import Foundation

/// Отвечает за парсинг CSV-файла с ингредиентами.
struct IngredientCSVParser {

    func parseFromBundle() throws -> [Ingredient] {
        guard let url = Bundle.main.url(forResource: "ingr", withExtension: "csv") else {
            throw IngredientServiceError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let csvString = String(data: data, encoding: .utf8) ?? ""

        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        guard lines.count > 1 else {
            throw IngredientServiceError.invalidFormat
        }

        let dataLines = Array(lines.dropFirst())
        var parsedIngredients: [Ingredient] = []

        for line in dataLines {
            let components = parseCSVLine(line)
            guard components.count >= 4 else { continue }

            let eCode = components[0].isEmpty ? nil : components[0]
            let statusString = components[1]
            let nameRu = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let nameEn = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let note = components[4].trimmingCharacters(in: .whitespacesAndNewlines)

            guard let status = IngredientStatus(rawValue: statusString) else { continue }

            let ingredient = Ingredient(
                eCode: eCode,
                status: status,
                nameRu: nameRu,
                nameEn: nameEn,
                note: note.isEmpty == false ? note : nil
            )
            parsedIngredients.append(ingredient)
        }

        return parsedIngredients
    }

    // MARK: - Private

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField.trimmingCharacters(in: .whitespaces))

        return result
    }
}
