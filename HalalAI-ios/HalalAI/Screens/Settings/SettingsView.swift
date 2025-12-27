//
//  SettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var chatService = ChatService.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var isApiKeyVisible = false
    @State private var maxTokensSlider: Double = 2048
    
    var body: some View {
        VStack {
            Form {
                if let user = authManager.currentUser {
                    Section(header: Text("Аккаунт")) {
                        HStack {
                            Text("Пользователь")
                            Spacer()
                            Text(user.username)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("API ключ провайдера")) {
                    if isApiKeyVisible {
                        TextField("Введите ключ", text: $chatService.userApiKey)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("Введите ключ", text: $chatService.userApiKey)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Toggle("Показать ключ", isOn: $isApiKeyVisible)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    
                    if !chatService.userApiKey.isEmpty {
                        Button(role: .destructive) {
                            chatService.userApiKey = ""
                        } label: {
                            Label("Очистить ключ", systemImage: "trash")
                        }
                    }
                    
                    Text("Если указать API ключ (например, OpenAI или совместимый), ответы будут генерироваться через удалённую модель. Без ключа применяется локальная модель HalalAI.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Section(header: Text("Удалённая модель")) {
                    if !chatService.availableModels.isEmpty {
                        Picker("Выберите модель", selection: $chatService.remoteModel) {
                            ForEach(chatService.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.system(.body, design: .monospaced))
                        Text("Доступно \(chatService.availableModels.count) моделей. По умолчанию: \(chatService.defaultRemoteModel)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        TextField("remote_model (например, xiaomi/mimo-v2-flash:free)", text: $chatService.remoteModel)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                        Text("Введите имя модели вручную. Список пока не загружен.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("max_tokens")
                            Spacer()
                            Text("\(Int(maxTokensSlider))")
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }
                        Slider(value: $maxTokensSlider, in: 16...6144, step: 16) {
                            Text("max_tokens")
                        } minimumValueLabel: {
                            Text("16")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } maximumValueLabel: {
                            Text("6144")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .onChange(of: maxTokensSlider) { newValue in
                            chatService.maxTokens = Int(newValue)
                        }
                        Text("Лимит токенов для генерации. Сервер принимает до 6144.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .onAppear {
                        maxTokensSlider = Double(chatService.maxTokens)
                        Task { await chatService.loadModels() }
                    }
                    Button("Обновить список моделей") {
                        Task { await chatService.loadModels() }
                    }
                    .font(.footnote)
                }
                
                Section(header: Text("Источники данных")) {
                    Text("Система RAG формирует контекст из «Перевода смыслов Священного Корана» Э.Р. Кулиева.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    
                    Link("Открыть источник",
                         destination: URL(string: "https://xn----8sbemuhsaeiwd9h5a9c.xn--p1ai/chitat-koran-na-russkom/elmir-kuliev/")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                
                // Выход из аккаунта
                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
//            .onTapGesture {
//                hideKeyboard()
//            }
        }
        .background {
            Color.greenBackground.ignoresSafeArea()
        }
    }
}

#Preview {
    SettingsView()
}
