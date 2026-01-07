//
//  IngredientScannerView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import SwiftUI
import UIKit

struct ScannerView: View {
    @Bindable var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.greenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.greenForeground)
                    }
                    Spacer()
                    Text("Сканирование состава")
                        .font(.headline)
                        .foregroundColor(.greenForeground)
                    Spacer()
                    Button(action: { viewModel.showManualInput.toggle() }) {
                        Image(systemName: "keyboard")
                            .font(.title2)
                            .foregroundColor(.greenForeground)
                    }
                }
                .padding()
                
                if viewModel.showManualInput {
                    manualInputView
                } else {
                    scannerView
                }
            }
        }
        .sheet(isPresented: $viewModel.showCamera) {
            CameraView(sourceType: viewModel.cameraSource) { images in
                viewModel.processImages(images)
            }
        }
        .sheet(isPresented: $viewModel.showResults) {
            IngredientResultsView(analysis: viewModel.analysis)
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.greenForeground)
                        Text("Обработка изображения...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color.greenForeground.opacity(0.9))
                    .cornerRadius(20)
                }
            }
        }
    }
    
    private var scannerView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.greenForeground)
            
            Text("Наведите камеру на состав продукта")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.greenForeground)
                .padding(.horizontal)
            
            Text("Или введите состав вручную")
                .font(.subheadline)
                .foregroundColor(.gray)
            
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.greenForeground)
                    .cornerRadius(12)
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
                    .foregroundColor(.greenForeground)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.greenForeground, lineWidth: 2)
                    )
                    .cornerRadius(12)
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
                .foregroundColor(.greenForeground)
                .padding(.top)
            
            TextEditor(text: $viewModel.manualInput)
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.processManualInput()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Проверить")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.greenForeground)
                .cornerRadius(12)
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
