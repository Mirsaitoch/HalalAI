//
//  IngredientScannerViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.01.2026.
//

import SwiftUI
import Vision

@MainActor
class IngredientScannerViewModel: ObservableObject {
    @Published var showCamera = false
    @Published var showManualInput = false
    @Published var showResults = false
    @Published var manualInput = ""
    @Published var analysis: ProductAnalysis?
    @Published var isLoading = false
    @Published var cameraSource: ImageSource = .camera
    
    private let ingredientService = IngredientService.shared
    
    init() {
        Task {
            try? await ingredientService.loadIngredients()
        }
    }
    
    func processImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        
        isLoading = true
        
        Task {
            // Обрабатываем все изображения и объединяем текст
            var allText: [String] = []
            
            for image in images {
                let text = await recognizeText(from: image)
                if !text.isEmpty {
                    allText.append(text)
                }
            }
            
            let combinedText = allText.joined(separator: " ")
            
            await MainActor.run {
                if !combinedText.isEmpty {
                    processText(combinedText)
                } else {
                    print("Не удалось распознать текст на изображении")
                }
                isLoading = false
            }
        }
    }
    
    func processManualInput() {
        let text = manualInput
        processText(text)
    }
    
    private func processText(_ text: String) {
        print("Распознанный текст: \(text)")
        
//        // Извлекаем текст от "Состав" до точки
//        let compositionText = extractCompositionText(from: text)
//        print("Извлеченный состав: \(compositionText)")
//        
//        if compositionText.isEmpty {
//            print("Не удалось найти состав в тексте")
//            isLoading = false
//            return
//        }
        
        Task {
            let analysis = await ingredientService.analyzeText(text)
            await MainActor.run {
                print("Найдено ингредиентов: \(analysis.ingredients.count)")
                print("Харам ингредиентов: \(analysis.haramIngredients.count)")
                self.analysis = analysis
                self.showResults = true
            }
        }
    }
    
    private func extractCompositionText(from text: String) -> String {
        // Ищем маркеры начала состава
        let compositionMarkers = ["Состав:", "Ingredients:", "Ингредиенты:", "Состав", "INGREDIENTS", "INGREDIENTS:"]
        var compositionStart: String.Index?
        
        for marker in compositionMarkers {
            if let range = text.range(of: marker, options: [.caseInsensitive, .diacriticInsensitive]) {
                compositionStart = range.upperBound
                break
            }
        }
        
        guard let startIndex = compositionStart else {
            return ""
        }
        
        // Берем текст после маркера
        var textAfterComposition = String(text[startIndex...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ищем первую точку, которая не является частью числа или E-кода
        // Ищем точку, за которой идет пробел или конец строки, или перед которой не цифра
        var dotIndex: String.Index?
        var searchIndex = textAfterComposition.startIndex
        
        while searchIndex < textAfterComposition.endIndex {
            if let foundIndex = textAfterComposition[searchIndex...].firstIndex(of: ".") {
                // Проверяем контекст вокруг точки
                let beforeIndex = textAfterComposition.index(before: foundIndex)
                let afterIndex = textAfterComposition.index(after: foundIndex)
                
                // Если точка не в числе (перед ней не цифра или после не цифра)
                let charBefore = beforeIndex >= textAfterComposition.startIndex ? textAfterComposition[beforeIndex] : " "
                let charAfter = afterIndex < textAfterComposition.endIndex ? textAfterComposition[afterIndex] : " "
                
                let isDigitBefore = charBefore.isNumber
                let isDigitAfter = charAfter.isNumber
                
                // Если точка не в числе и после нее пробел или конец - это конец состава
                if !isDigitBefore && !isDigitAfter && (charAfter.isWhitespace || afterIndex == textAfterComposition.endIndex) {
                    dotIndex = foundIndex
                    break
                }
                
                // Продолжаем поиск после этой точки
                searchIndex = textAfterComposition.index(after: foundIndex)
            } else {
                break
            }
        }
        
        if let dotIndex = dotIndex {
            // Берем текст до точки (не включая точку)
            let compositionText = String(textAfterComposition[..<dotIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return compositionText
        }
        
        // Если точки нет, ищем другие маркеры конца состава
        let endMarkers = [
            "Пищевая ценность",
            "Nutrition",
            "Nutritional",
            "Пищевая и энергетическая",
            "Энергетическая ценность",
            "Количество",
            "ВСТРЯХНУТЬ",
            "Температура",
            "Дата",
            "ГОСТ",
            "Изготовитель"
        ]
        
        for marker in endMarkers {
            if let range = textAfterComposition.range(of: marker, options: [.caseInsensitive, .diacriticInsensitive]) {
                let compositionText = String(textAfterComposition[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return compositionText
            }
        }
        
        // Если ничего не найдено, берем текст до конца (но ограничиваем длиной)
        let maxLength = min(textAfterComposition.count, 1000)
        let compositionText = String(textAfterComposition.prefix(maxLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return compositionText
    }
    
    private func recognizeText(from image: UIImage) async -> String {
        guard let cgImage = image.cgImage else {
            print("Ошибка: не удалось получить CGImage")
            return ""
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("Ошибка распознавания текста: \(error.localizedDescription)")
                    continuation.resume(returning: "")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("Ошибка: не удалось получить результаты распознавания")
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let result = recognizedStrings.joined(separator: " ")
                print("Распознано символов: \(result.count)")
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ru-RU", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Ошибка выполнения запроса распознавания: \(error.localizedDescription)")
                continuation.resume(returning: "")
            }
        }
    }
}
