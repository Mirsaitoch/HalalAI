//
//  IngredientMatcher.swift
//  HalalAI
//
//  Extracted from IngredientService.swift
//

import Foundation

/// Алгоритм сопоставления текста с базой ингредиентов:
/// извлечение E-кодов, скоринг совпадений, фильтрация лучших результатов.
struct IngredientMatcher {

    typealias CandidateMatch = (ingredient: Ingredient, name: String, score: Double)

    // MARK: - Public

    /// Анализирует текст и возвращает найденные ингредиенты с общим статусом.
    func analyze(text: String, ingredients: [Ingredient]) -> ProductAnalysis {
        var detectedIngredients: [DetectedIngredient] = []
        var foundECodes: Set<String> = []

        // 1. Извлекаем E-коды из текста
        let ecodes = extractECodes(from: text)

        // 2. Проверяем каждый E-код
        for ecode in ecodes {
            if let ingredient = ingredients.first(where: { $0.eCode?.uppercased() == ecode.uppercased() }) {
                let detected = DetectedIngredient(name: ecode, matchedIngredient: ingredient)
                detectedIngredients.append(detected)
                foundECodes.insert(ecode.uppercased())
            }
        }

        // 3. Проверяем по названиям ингредиентов (гибкий поиск по словам)
        let textLower = text.lowercased()
        var candidateMatches: [CandidateMatch] = []

        for ingredient in ingredients {
            if let eCode = ingredient.eCode, foundECodes.contains(eCode.uppercased()) {
                continue
            }

            let nameRuLower = ingredient.nameRu.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !nameRuLower.isEmpty,
               let score = matchesIngredientWithScore(name: nameRuLower, in: textLower) {
                candidateMatches.append((ingredient: ingredient, name: ingredient.nameRu, score: score))
            }

            let nameEnLower = ingredient.nameEn.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !nameEnLower.isEmpty,
               let score = matchesIngredientWithScore(name: nameEnLower, in: textLower) {
                candidateMatches.append((ingredient: ingredient, name: ingredient.nameEn, score: score))
            }
        }

        // 4. Фильтруем и выбираем лучшие совпадения
        let filteredMatches = filterBestMatches(candidates: candidateMatches, text: textLower)

        var foundIngredientKeys: Set<String> = []
        for match in filteredMatches {
            let key = "\(match.ingredient.eCode ?? "")_\(match.ingredient.id)"
            if !foundIngredientKeys.contains(key) {
                foundIngredientKeys.insert(key)
                let detected = DetectedIngredient(name: match.name, matchedIngredient: match.ingredient)
                detectedIngredients.append(detected)
            }
        }

        let haramIngredients = detectedIngredients.filter { $0.status == .haram }
        let mushboohIngredients = detectedIngredients.filter { $0.status == .mushbooh }

        let overallStatus: IngredientStatus
        if !haramIngredients.isEmpty {
            overallStatus = .haram
        } else if !mushboohIngredients.isEmpty {
            overallStatus = .mushbooh
        } else if !detectedIngredients.isEmpty && detectedIngredients.allSatisfy({ $0.status == .halal }) {
            overallStatus = .halal
        } else {
            overallStatus = .unknown
        }

        return ProductAnalysis(
            ingredients: detectedIngredients,
            overallStatus: overallStatus,
            haramIngredients: haramIngredients,
            mushboohIngredients: mushboohIngredients
        )
    }

    // MARK: - E-Code Extraction

    private func extractECodes(from text: String) -> [String] {
        var ecodes: [String] = []

        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        for word in words {
            let wordUpper = word.uppercased()
            if (wordUpper.hasPrefix("E") || wordUpper.hasPrefix("e")) && wordUpper.count > 1 {
                let remaining = String(wordUpper.dropFirst())

                if !remaining.isEmpty {
                    let lastChar = remaining.last!
                    let validEndChars = CharacterSet(charactersIn: "0123456789abcdefi")

                    if validEndChars.contains(lastChar.unicodeScalars.first!) {
                        let validChars = CharacterSet.alphanumerics
                        if remaining.rangeOfCharacter(from: validChars.inverted) == nil {
                            ecodes.append(wordUpper)
                        }
                    }
                }
            }
        }

        return Array(Set(ecodes))
    }

    // MARK: - Score Matching

    /// Возвращает оценку совпадения (0.0–1.0) или nil, если не найдено.
    private func matchesIngredientWithScore(name: String, in text: String) -> Double? {
        let nameLower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let textLower = text.lowercased()

        // 1. Если название очень короткое (< 5 символов), только точное совпадение
        if nameLower.count < 5 {
            if hasWordBoundaryMatch(nameLower, in: textLower) {
                return 0.7
            }
            return nil
        }

        // 2. Точное совпадение с границами слов — самый высокий score
        if hasWordBoundaryMatch(nameLower, in: textLower) {
            return 1.0
        }

        // 3. Поиск по словам
        let allIngredientWords = extractWords(from: name, minLength: 1)
        let significantIngredientWords = extractWords(from: name, minLength: 4)

        guard !significantIngredientWords.isEmpty else {
            return nil
        }

        var matchedSignificantWords = 0
        for word in significantIngredientWords {
            if hasWordBoundaryMatch(word, in: textLower) {
                matchedSignificantWords += 1
            }
        }

        let shortWords = allIngredientWords.filter { $0.count >= 3 && $0.count < 4 }
        var matchedShortWords = 0
        for word in shortWords {
            if hasWordBoundaryMatch(word, in: textLower) {
                matchedShortWords += 1
            }
        }

        if !shortWords.isEmpty && matchedShortWords < shortWords.count {
            return nil
        }

        let matchRatio = Double(matchedSignificantWords) / Double(significantIngredientWords.count)

        let minRequiredRatio: Double
        if significantIngredientWords.count == 1 {
            minRequiredRatio = 1.0
        } else if significantIngredientWords.count == 2 {
            minRequiredRatio = 1.0
        } else if significantIngredientWords.count == 3 {
            minRequiredRatio = 0.67
        } else {
            minRequiredRatio = 0.75
        }

        if matchRatio >= minRequiredRatio {
            let score = matchRatio * 0.85
            return score
        }

        return nil
    }

    // MARK: - Best Match Filtering

    /// Фильтрует кандидатов, оставляя только лучшие совпадения.
    private func filterBestMatches(candidates: [CandidateMatch], text: String) -> [CandidateMatch] {
        if candidates.isEmpty { return [] }

        let filteredByScore = candidates.filter { $0.score >= 0.7 }

        let sorted = filteredByScore.sorted { first, second in
            if first.score != second.score {
                return first.score > second.score
            }
            return first.name.count < second.name.count
        }

        var result: [CandidateMatch] = []
        var usedPositions: Set<Int> = []
        let textLower = text.lowercased()

        for (index, candidate) in sorted.enumerated() {
            if usedPositions.contains(index) { continue }

            let candidateNameLower = candidate.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let hasExactMatch = hasWordBoundaryMatch(candidateNameLower, in: textLower)
            var isSubset = false

            for (otherIndex, other) in sorted.enumerated() {
                if index == otherIndex || usedPositions.contains(otherIndex) { continue }

                let otherNameLower = other.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if otherNameLower.contains(candidateNameLower) &&
                   candidateNameLower.count < otherNameLower.count {

                    let candidateWords = Set(extractWords(from: candidateNameLower, minLength: 4))
                    let otherWords = Set(extractWords(from: otherNameLower, minLength: 4))
                    let additionalWords = otherWords.subtracting(candidateWords)

                    let candidateIsStartOfPhrase = hasFollowingWordsMatch(candidateNameLower, in: textLower)
                    let hasExactMatchForOther = hasWordBoundaryMatch(otherNameLower, in: textLower)
                    let allAdditionalWordsInText = additionalWords.isEmpty || additionalWords.allSatisfy {
                        hasWordBoundaryMatch($0, in: textLower)
                    }

                    if hasExactMatch && !hasExactMatchForOther { continue }
                    if hasExactMatch && !allAdditionalWordsInText { continue }
                    if candidateIsStartOfPhrase && !hasExactMatchForOther { continue }

                    if hasExactMatchForOther && !hasExactMatch {
                        isSubset = true
                        break
                    }

                    if hasExactMatchForOther && allAdditionalWordsInText {
                        isSubset = true
                        break
                    }

                    if hasExactMatch && hasExactMatchForOther {
                        if other.score > candidate.score ||
                           (other.score == candidate.score && otherNameLower.count < candidateNameLower.count) {
                            isSubset = true
                            break
                        }
                    }

                    if !hasExactMatch && !hasExactMatchForOther &&
                       allAdditionalWordsInText &&
                       other.score > candidate.score + 0.1 {
                        let lengthDiff = otherNameLower.count - candidateNameLower.count
                        if lengthDiff > 2 {
                            isSubset = true
                            break
                        }
                    }

                    if !allAdditionalWordsInText { continue }
                }

                // Обратная проверка: этот ингредиент содержит другой
                if candidateNameLower.contains(otherNameLower) &&
                   otherNameLower.count < candidateNameLower.count {
                    let hasExactMatchForOther = hasWordBoundaryMatch(otherNameLower, in: textLower)
                    if hasExactMatchForOther && !hasExactMatch {
                        usedPositions.insert(index)
                        break
                    }
                }
            }

            if !isSubset {
                result.append(candidate)
                usedPositions.insert(index)
            }
        }

        return result
    }

    // MARK: - Helpers

    private func hasWordBoundaryMatch(_ word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    private func hasFollowingWordsMatch(_ word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\s+\\w+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    private func extractWords(from string: String, minLength: Int) -> [String] {
        string.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count >= minLength }
    }
}
