//
//  IngredientScannerViewModel.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.01.2026.
//

import SwiftUI
import Vision


extension ScannerView {
    @MainActor
    @Observable
    final class ViewModel: ObservableObject {
        var showCamera = false
        var showManualInput = false
        var showResults = false
        var manualInput = ""
        var analysis: ProductAnalysis?
        var isLoading = false
        var cameraSource: ImageSource = .camera
        
        private let ingredientService: IngredientService
        
        init(ingredientService: IngredientService) {
            self.ingredientService = ingredientService
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

}
