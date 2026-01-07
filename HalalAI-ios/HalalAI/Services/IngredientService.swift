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
class IngredientServiceImpl: IngredientService {
    private var ingredients: [Ingredient] = []
    private var ingredientsLoaded = false
    
    init() {
        print("Создаем AuthManagerImpl")
    }
    
    func loadIngredients() async throws -> [Ingredient] {
        if ingredientsLoaded {
            return ingredients
        }
        
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
        
        ingredients = parsedIngredients
        ingredientsLoaded = true
        
        return ingredients
    }
            
    func analyzeText(_ text: String) -> ProductAnalysis {
        var detectedIngredients: [DetectedIngredient] = []
        var foundECodes: Set<String> = []
        
        // 1. Извлекаем E-коды из текста
        let ecodes = extractECodes(from: text)
        print("Найдено E-кодов: \(ecodes.count)")
        
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
        var candidateMatches: [(ingredient: Ingredient, name: String, score: Double)] = []
        
        for ingredient in ingredients {
            // Пропускаем если уже нашли по E-коду
            if let eCode = ingredient.eCode, foundECodes.contains(eCode.uppercased()) {
                continue
            }
            
            // Проверяем по русскому названию
            let nameRuLower = ingredient.nameRu.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !nameRuLower.isEmpty {
                if let score = matchesIngredientWithScore(name: nameRuLower, in: textLower) {
                    print("🔍 Найдено совпадение: '\(ingredient.nameRu)' (score: \(score))")
                    candidateMatches.append((ingredient: ingredient, name: ingredient.nameRu, score: score))
                }
            }
            
            // Проверяем по английскому названию
            let nameEnLower = ingredient.nameEn.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !nameEnLower.isEmpty {
                if let score = matchesIngredientWithScore(name: nameEnLower, in: textLower) {
                    print("🔍 Найдено совпадение: '\(ingredient.nameEn)' (score: \(score))")
                    candidateMatches.append((ingredient: ingredient, name: ingredient.nameEn, score: score))
                }
            }
        }
        
        // 4. Фильтруем и выбираем лучшие совпадения
        print("📊 Всего кандидатов до фильтрации: \(candidateMatches.count)")
        let filteredMatches = filterBestMatches(candidates: candidateMatches, text: textLower)
        print("✅ Кандидатов после фильтрации: \(filteredMatches.count)")
        
        // Добавляем отфильтрованные ингредиенты
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
    
    private func extractECodes(from text: String) -> [String] {
        var ecodes: [String] = []
        
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        for word in words {
            let wordUpper = word.uppercased()
            // Проверяем, начинается ли с E или e
            if (wordUpper.hasPrefix("E") || wordUpper.hasPrefix("e")) && wordUpper.count > 1 {
                let remaining = String(wordUpper.dropFirst())
                
                // Проверяем, что заканчивается цифрой (0-9) или буквой (a-f, i, ii)
                if !remaining.isEmpty {
                    let lastChar = remaining.last!
                    let validEndChars = CharacterSet(charactersIn: "0123456789abcdefi")
                    
                    if validEndChars.contains(lastChar.unicodeScalars.first!) {
                        // Проверяем, что остаток содержит только валидные символы
                        let validChars = CharacterSet.alphanumerics
                        if remaining.rangeOfCharacter(from: validChars.inverted) == nil {
                            ecodes.append(wordUpper)
                        }
                    }
                }
            }
        }
        
        return Array(Set(ecodes)) // Убираем дубликаты
    }
    
    // MARK: - Private
    
    // Возвращает оценку совпадения (0.0 - 1.0) или nil если не найдено
    // Более высокий score = более точное совпадение
    private func matchesIngredientWithScore(name: String, in text: String) -> Double? {
        let nameLower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let textLower = text.lowercased()
        
        // 1. Если название ингредиента очень короткое (меньше 5 символов), используем только точное совпадение
        if nameLower.count < 5 {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: nameLower))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: textLower.utf16.count)
                if regex.firstMatch(in: textLower, options: [], range: range) != nil {
                    return 0.7 // Низкий score для очень коротких слов
                }
            }
            return nil
        }
        
        // 2. Точное совпадение с границами слов - самый высокий score
        let exactPattern = "\\b\(NSRegularExpression.escapedPattern(for: nameLower))\\b"
        if let regex = try? NSRegularExpression(pattern: exactPattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: textLower.utf16.count)
            if regex.firstMatch(in: textLower, options: [], range: range) != nil {
                return 1.0 // Идеальное совпадение
            }
        }
        
        // 3. Поиск по словам
        // Извлекаем ВСЕ слова (включая короткие), но для подсчета используем только значимые (>= 4 символов)
        let extractAllWords: (String) -> [String] = { str in
            str.components(separatedBy: CharacterSet.alphanumerics.inverted)
                .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        let extractSignificantWords: (String) -> [String] = { str in
            str.components(separatedBy: CharacterSet.alphanumerics.inverted)
                .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count >= 4 }
        }
        
        let allIngredientWords = extractAllWords(name)
        let significantIngredientWords = extractSignificantWords(name)
        
        guard !significantIngredientWords.isEmpty else {
            return nil
        }
        
        // Проверяем совпадения значимых слов
        var matchedSignificantWords = 0
        for word in significantIngredientWords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: textLower.utf16.count)
                if regex.firstMatch(in: textLower, options: [], range: range) != nil {
                    matchedSignificantWords += 1
                }
            }
        }
        
        // Проверяем совпадения коротких слов (3-4 символа) - они тоже важны!
        // Например, "пива" в "ароматизатор пива" должно быть найдено
        let shortWords = allIngredientWords.filter { $0.count >= 3 && $0.count < 4 }
        var matchedShortWords = 0
        for word in shortWords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: textLower.utf16.count)
                if regex.firstMatch(in: textLower, options: [], range: range) != nil {
                    matchedShortWords += 1
                }
            }
        }
        
        // Если есть короткие слова, они тоже должны совпадать
        if !shortWords.isEmpty && matchedShortWords < shortWords.count {
            print("    ⚠️ Не все короткие слова найдены для '\(name)': найдено \(matchedShortWords) из \(shortWords.count) (\(shortWords))")
            return nil // Если не все короткие слова найдены, не считаем совпадением
        }
        
        // Вычисляем score на основе процента совпадений значимых слов
        let matchRatio = Double(matchedSignificantWords) / Double(significantIngredientWords.count)
        
        // Требуем минимум 70% совпадений
        // Для одного слова - требуется 100%
        // Для 2-3 слов - требуется минимум 2 слова (67-100%)
        // Для 4+ слов - требуется минимум 75%
        let minRequiredRatio: Double
        if significantIngredientWords.count == 1 {
            minRequiredRatio = 1.0 // 100% для одного слова
        } else if significantIngredientWords.count == 2 {
            minRequiredRatio = 1.0 // 100% для двух слов (оба должны совпасть)
        } else if significantIngredientWords.count == 3 {
            minRequiredRatio = 0.67 // 67% (минимум 2 из 3)
        } else {
            minRequiredRatio = 0.75 // 75% для длинных названий
        }
        
        if matchRatio >= minRequiredRatio {
            // Для частичных совпадений даем меньший score
            let score = matchRatio * 0.85 // Максимум 0.85 для частичных совпадений
            print("    📊 Score для '\(name)': \(score) (совпало \(matchedSignificantWords)/\(significantIngredientWords.count) значимых слов, коротких: \(matchedShortWords)/\(shortWords.count))")
            return score
        }
        
        return nil
    }
    
    // Старый метод для обратной совместимости
    private func matchesIngredient(name: String, in text: String) -> Bool {
        return matchesIngredientWithScore(name: name, in: text) != nil
    }
    
    // Фильтрует кандидатов, оставляя только лучшие совпадения
    // Удаляет частичные совпадения, если есть более полные
    private func filterBestMatches(candidates: [(ingredient: Ingredient, name: String, score: Double)], text: String) -> [(ingredient: Ingredient, name: String, score: Double)] {
        if candidates.isEmpty {
            return []
        }
        
        // Фильтруем по минимальному score (только совпадения с score >= 0.7)
        let filteredByScore = candidates.filter { $0.score >= 0.7 }
        print("🔧 После фильтрации по score (>= 0.7): \(filteredByScore.count) кандидатов")
        
        // Сортируем по score (от большего к меньшему), затем по длине (более короткие при одинаковом score)
        let sorted = filteredByScore.sorted { first, second in
            if first.score != second.score {
                return first.score > second.score
            }
            // При одинаковом score предпочитаем более короткие названия (более точные совпадения)
            return first.name.count < second.name.count
        }
        
        print("📋 Отсортированные кандидаты:")
        for (idx, candidate) in sorted.enumerated() {
            print("  \(idx + 1). '\(candidate.name)' (score: \(candidate.score), длина: \(candidate.name.count))")
        }
        
        var result: [(ingredient: Ingredient, name: String, score: Double)] = []
        var usedPositions: Set<Int> = []
        let textLower = text.lowercased()
        
        for (index, candidate) in sorted.enumerated() {
            if usedPositions.contains(index) {
                continue
            }
            
            let candidateNameLower = candidate.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            var isSubset = false
            
            // Проверяем, есть ли в тексте точное совпадение с этим кандидатом (как отдельное слово)
            let hasExactMatch: Bool = {
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: candidateNameLower))\\b"
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                    let range = NSRange(location: 0, length: textLower.utf16.count)
                    let found = regex.firstMatch(in: textLower, options: [], range: range) != nil
                    if found {
                        print("  ✓ Точное совпадение найдено для '\(candidate.name)'")
                    }
                    return found
                }
                return false
            }()
            
            // Проверяем, не является ли этот ингредиент частью другого, более полного
            for (otherIndex, other) in sorted.enumerated() {
                if index == otherIndex || usedPositions.contains(otherIndex) {
                    continue
                }
                
                let otherNameLower = other.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Если другой ингредиент содержит этот полностью
                if otherNameLower.contains(candidateNameLower) && 
                   candidateNameLower.count < otherNameLower.count {
                    
                    // Извлекаем дополнительные слова из длинного названия, которых нет в коротком
                    let candidateWords = Set(candidateNameLower.components(separatedBy: CharacterSet.alphanumerics.inverted)
                        .filter { !$0.isEmpty && $0.count >= 4 })
                    let otherWords = Set(otherNameLower.components(separatedBy: CharacterSet.alphanumerics.inverted)
                        .filter { !$0.isEmpty && $0.count >= 4 })
                    let additionalWords = otherWords.subtracting(candidateWords)
                    
                    print("  🔍 Дополнительные слова в '\(other.name)': \(additionalWords)")
                    
                    // Обратная ситуация: если короткое название найдено в тексте как начало более длинной фразы
                    // Например, в тексте "молоко нормализованное", а в базе "молоко"
                    // Проверяем, что короткое название стоит в начале более длинной фразы в тексте
                    let candidateIsStartOfPhrase: Bool = {
                        // Ищем паттерн: короткое название + пробел + еще слова
                        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: candidateNameLower))\\s+\\w+"
                        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                            let range = NSRange(location: 0, length: textLower.utf16.count)
                            return regex.firstMatch(in: textLower, options: [], range: range) != nil
                        }
                        return false
                    }()
                    
                    if candidateIsStartOfPhrase {
                        print("  🔍 Короткое '\(candidate.name)' является началом фразы в тексте")
                    }
                    
                    // Проверяем, есть ли в тексте точное совпадение с более длинным названием (как отдельное слово)
                    let hasExactMatchForOther: Bool = {
                        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: otherNameLower))\\b"
                        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                            let range = NSRange(location: 0, length: textLower.utf16.count)
                            let found = regex.firstMatch(in: textLower, options: [], range: range) != nil
                            if found {
                                print("  ✓ Точное совпадение найдено для '\(other.name)'")
                            }
                            return found
                        }
                        return false
                    }()
                    
                    // Проверяем, есть ли в тексте все дополнительные слова из длинного названия
                    let allAdditionalWordsInText = additionalWords.isEmpty || additionalWords.allSatisfy { word in
                        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
                        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                            let range = NSRange(location: 0, length: textLower.utf16.count)
                            return regex.firstMatch(in: textLower, options: [], range: range) != nil
                        }
                        return false
                    }
                    
                    print("  🔍 Все дополнительные слова найдены в тексте: \(allAdditionalWordsInText)")
                    print("  🔄 Сравнение: '\(candidate.name)' (score: \(candidate.score), exact: \(hasExactMatch)) vs '\(other.name)' (score: \(other.score), exact: \(hasExactMatchForOther), доп. слова в тексте: \(allAdditionalWordsInText))")
                    
                    // Если более короткое название точно совпадает с текстом, а длинное - нет
                    // то предпочитаем короткое
                    if hasExactMatch && !hasExactMatchForOther {
                        print("  ✅ Выбираем короткое '\(candidate.name)' (точное совпадение, длинное не найдено)")
                        // Короткое название точнее соответствует тексту
                        continue
                    }
                    
                    // Если короткое точно совпадает, но в тексте нет дополнительных слов из длинного
                    // то предпочитаем короткое (например, "ароматизатор" вместо "ароматизатор пива", если в тексте нет "пива")
                    if hasExactMatch && !allAdditionalWordsInText {
                        print("  ✅ Выбираем короткое '\(candidate.name)' (точное совпадение, в тексте нет дополнительных слов из длинного)")
                        continue
                    }
                    
                    // Обратная ситуация: если короткое название является началом фразы в тексте
                    // (например, "молоко нормализованное" в тексте, "молоко" в базе)
                    // и длинное название не найдено точно, то выбираем короткое
                    if candidateIsStartOfPhrase && !hasExactMatchForOther {
                        print("  ✅ Выбираем короткое '\(candidate.name)' (является началом фразы в тексте, длинное не найдено)")
                        continue
                    }
                    
                    // Если более длинное название точно совпадает, а короткое - нет
                    // то предпочитаем длинное
                    if hasExactMatchForOther && !hasExactMatch {
                        print("  ❌ Отклоняем короткое '\(candidate.name)', выбираем длинное '\(other.name)' (точное совпадение)")
                        isSubset = true
                        break
                    }
                    
                    // Если длинное точно совпадает И все дополнительные слова есть в тексте
                    if hasExactMatchForOther && allAdditionalWordsInText {
                        print("  ❌ Отклоняем короткое '\(candidate.name)', выбираем длинное '\(other.name)' (точное совпадение + все доп. слова в тексте)")
                        isSubset = true
                        break
                    }
                    
                    // Если оба совпадают, предпочитаем то, у которого выше score
                    // или более короткое при одинаковом score
                    if hasExactMatch && hasExactMatchForOther {
                        if other.score > candidate.score || 
                           (other.score == candidate.score && otherNameLower.count < candidateNameLower.count) {
                            print("  ❌ Отклоняем '\(candidate.name)', выбираем '\(other.name)' (оба точные, но у другого выше score или короче)")
                            isSubset = true
                            break
                        } else {
                            print("  ✅ Оставляем '\(candidate.name)' (оба точные, но у этого выше score или короче)")
                        }
                    }
                    
                    // Если ни одно не совпадает точно, но длинное имеет значительно больший score
                    // И все дополнительные слова есть в тексте
                    if !hasExactMatch && !hasExactMatchForOther && 
                       allAdditionalWordsInText && 
                       other.score > candidate.score + 0.1 {
                        let lengthDiff = otherNameLower.count - candidateNameLower.count
                        if lengthDiff > 2 {
                            print("  ❌ Отклоняем '\(candidate.name)', выбираем '\(other.name)' (длинное имеет больший score и все доп. слова в тексте)")
                            isSubset = true
                            break
                        }
                    }
                    
                    // Если в тексте нет дополнительных слов из длинного названия, предпочитаем короткое
                    if !allAdditionalWordsInText {
                        print("  ✅ Выбираем короткое '\(candidate.name)' (в тексте нет дополнительных слов из длинного)")
                        continue
                    }
                }
                
                // Если этот ингредиент содержит другой полностью
                if candidateNameLower.contains(otherNameLower) && 
                   otherNameLower.count < candidateNameLower.count {
                    let hasExactMatchForOther: Bool = {
                        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: otherNameLower))\\b"
                        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                            let range = NSRange(location: 0, length: textLower.utf16.count)
                            return regex.firstMatch(in: textLower, options: [], range: range) != nil
                        }
                        return false
                    }()
                    
                    if hasExactMatchForOther && !hasExactMatch {
                        usedPositions.insert(index)
                        break
                    }
                }
            }
            
            if !isSubset {
                print("  ✅ Добавляем в результат: '\(candidate.name)' (score: \(candidate.score))")
                result.append(candidate)
                usedPositions.insert(index)
            } else {
                print("  ❌ Пропускаем: '\(candidate.name)' (является подмножеством другого)")
            }
        }
        
        return result
    }
    
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

