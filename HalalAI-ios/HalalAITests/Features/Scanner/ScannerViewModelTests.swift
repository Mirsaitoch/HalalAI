//
//  ScannerViewModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct ScannerViewModelTests {

    @Test("openCamera sets camera source and shows camera")
    func openCamera() {
        let (vm, _) = makeSUT()

        vm.openCamera()

        #expect(vm.showCamera == true)
        #expect(vm.cameraSource == .camera)
    }

    @Test("openPhotoLibrary sets photo library source and shows camera")
    func openPhotoLibrary() {
        let (vm, _) = makeSUT()

        vm.openPhotoLibrary()

        #expect(vm.showCamera == true)
        #expect(vm.cameraSource == .photoLibrary)
    }

    @Test("processManualInput calls analyzeText on service")
    func processManualInput() async throws {
        let (vm, service) = makeSUT()
        let halalIngredient = Ingredient(
            eCode: "E100", status: .halal, nameRu: "Куркумин", nameEn: "Curcumin"
        )
        let detected = DetectedIngredient(name: "E100", matchedIngredient: halalIngredient)
        service.analyzeResult = ProductAnalysis(
            ingredients: [detected],
            overallStatus: .halal,
            haramIngredients: [],
            mushboohIngredients: []
        )
        vm.manualInput = "E100 куркумин"

        vm.processManualInput()

        // Wait for the async Task inside processText
        try await Task.sleep(for: .milliseconds(100))

        #expect(service.analyzeCallCount >= 1)
        #expect(vm.analysis != nil)
        #expect(vm.showResults == true)
    }

    @Test("processImages with empty array does nothing")
    func processEmptyImages() {
        let (vm, _) = makeSUT()

        vm.processImages([])

        #expect(vm.isLoading == false)
    }

    @Test("Initial state is correct")
    func initialState() {
        let (vm, _) = makeSUT()
        #expect(vm.showCamera == false)
        #expect(vm.showManualInput == false)
        #expect(vm.showResults == false)
        #expect(vm.analysis == nil)
        #expect(vm.isLoading == false)
        #expect(vm.manualInput == "")
    }

    // MARK: - Helpers

    private func makeSUT() -> (ScannerView.ViewModel, MockIngredientService) {
        let service = MockIngredientService()
        let authManager = MockAuthManager()
        let vm = ScannerView.ViewModel(ingredientService: service, authManager: authManager)
        return (vm, service)
    }
}
