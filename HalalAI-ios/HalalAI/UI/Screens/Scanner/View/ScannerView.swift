//
//  IngredientScannerView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import SwiftUI
import UIKit

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
                    .foregroundStyle(.greenForeground)
                    .labelStyle(.iconOnly)
                    Spacer()
                    Text("Сканирование состава")
                        .font(.headline)
                        .foregroundStyle(.greenForeground)
                    Spacer()
                    Button("Ввод вручную", systemImage: "keyboard") {
                        vm.showManualInput.toggle()
                    }
                    .font(.title2)
                    .foregroundStyle(.greenForeground)
                    .labelStyle(.iconOnly)
                }
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
        .overlay {
            if vm.authManager.isGuest {
                GuestAuthPromptView(featureName: "сканирование продуктов", authManager: vm.authManager)
            }
        }
        .overlay {
            if vm.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.greenForeground)
                        Text("Обработка изображения...")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color.greenForeground.opacity(0.9))
                    .clipShape(.rect(cornerRadius: 20))
                }
            }
        }
    }
    
    private var scannerView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.greenForeground)
            
            Text("Наведите камеру на состав продукта")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.greenForeground)
                .padding(.horizontal)
            
            Text("Или введите состав вручную")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            VStack(spacing: 15) {
                Button(action: {
                    viewModel.showCamera = true
                    viewModel.cameraSource = .camera
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Сфотографировать")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.greenForeground)
                    .clipShape(.rect(cornerRadius: 12))
                }
                
                Button(action: {
                    viewModel.showCamera = true
                    viewModel.cameraSource = .photoLibrary
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Выбрать из галереи")
                    }
                    .font(.headline)
                    .foregroundStyle(.greenForeground)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.greenForeground, lineWidth: 2)
                    )
                    .clipShape(.rect(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private var manualInputView: some View {
        VStack(spacing: 20) {
            Text("Введите состав продукта")
                .font(.headline)
                .foregroundStyle(.greenForeground)
                .padding(.top)
            
            TextEditor(text: $viewModel.manualInput)
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal)
            
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
                .background(Color.greenForeground)
                .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.horizontal)
            .disabled(viewModel.manualInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Camera View

enum ImageSource {
    case camera
    case photoLibrary
}

struct CameraView: UIViewControllerRepresentable {
    let sourceType: ImageSource
    let onImageCaptured: ([UIImage]) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType == .camera ? .camera : .photoLibrary
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
        }
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: ([UIImage]) -> Void
        
        init(onImageCaptured: @escaping ([UIImage]) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                picker.dismiss(animated: true) {
                    self.onImageCaptured([image])
                }
            } else {
                picker.dismiss(animated: true)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
