//
//  IngredientScannerView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import SwiftUI

struct ScannerView: View {
    @State private var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    init(ingredientService: IngredientService, authManager: AuthManager) {
        _viewModel = State(initialValue: ViewModel(ingredientService: ingredientService, authManager: authManager))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        ZStack {
            Color.greenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок
                HStack {
                    Button("Назад", systemImage: "chevron.left") {
                        dismiss()
                    }
                    .font(.title2)
                    .labelStyle(.iconOnly)
                    Spacer()
                    Text("Сканирование состава")
                        .font(.headline)
                    Spacer()
                    Button("Ввод вручную", systemImage: vm.showManualInput ? "camera" : "keyboard") {
                        vm.showManualInput.toggle()
                    }
                    .font(.title2)
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("scanner_mode_toggle")
                }
                .animation(.easeInOut, value: vm.showManualInput)
                .foregroundStyle(.darkGreen)
                .padding()
                
                if vm.showManualInput {
                    manualInputView
                } else {
                    scannerView
                }
            }
        }
        .sheet(isPresented: $vm.showCamera) {
            CameraView(sourceType: vm.cameraSource) { images in
                vm.processImages(images)
            }
        }
        .sheet(isPresented: $vm.showResults) {
            IngredientResultsView(analysis: vm.analysis)
        }
//        .overlay {
//            if vm.authManager.isGuest {
//                GuestAuthPromptView(featureName: "сканирование продуктов", authManager: vm.authManager)
//            }
//        }
        .overlay {
            if vm.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .foregroundStyle(.white)
                        Text("Обработка изображения...")
                            .foregroundStyle(.black)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(.darkGreen.opacity(0.9))
                    .clipShape(.rect(cornerRadius: 20))
                }
            }
        }
    }
    
    private var scannerView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "camera.fill")
                .font(.system(size: 70))
                .foregroundStyle(.darkGreen)
            
            Text("Сфотографируйте или выберите в галерее состав продукта")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.darkGreen)
                .padding(.horizontal)

            VStack(spacing: 15) {
                Button(action: viewModel.openCamera) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Сфотографировать")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.darkGreen)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .accessibilityIdentifier("scanner_camera_button")

                Button(action: viewModel.openPhotoLibrary) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Выбрать из галереи")
                    }
                    .font(.headline)
                    .foregroundStyle(.darkGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.darkGreen, lineWidth: 2)
                    )
                    .clipShape(.rect(cornerRadius: 12))
                }
                .accessibilityIdentifier("scanner_gallery_button")
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private var manualInputView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "keyboard.fill")
                .font(.system(size: 70))
                .foregroundStyle(.darkGreen)
        
            Text("Введите состав продукта")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.darkGreen)
                .padding(.horizontal)
            
            TextEditor(text: $viewModel.manualInput)
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal)
                .accessibilityIdentifier("scanner_manual_input")

            Button(action: {
                viewModel.processManualInput()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Проверить")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.darkGreen)
                .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.horizontal)
            .disabled(viewModel.manualInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("scanner_check_button")
            
            Spacer()
        }
        .padding()
    }
}



