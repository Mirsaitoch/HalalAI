//
//  SettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Form {
                // Раздел аккаунта
                accountSection
                // Раздел API ключа
                apiKeySection
                // Раздел удаленной модели
                remoteModelSection
                // Раздел источников данных
                dataSourcesSection
                // Выход из аккаунта
                logoutSection
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.greenBackground.ignoresSafeArea())
        }
        .background(Color.greenBackground.ignoresSafeArea())
        .onAppear {
            // Инициализация слайдера
            viewModel.maxTokensSlider = Double(viewModel.chatService.maxTokens)
            // Загрузка моделей при появлении
            Task {
                await viewModel.chatService.loadModels()
            }
        }
        .onChange(of: viewModel.maxTokensSlider) { newValue in
            // Обновление значения в сервисе при изменении слайдера
            viewModel.chatService.maxTokens = Int(newValue)
        }
    }
    
    // MARK: - Subviews
    
    private var accountSection: some View {
        Section(header: Text("Аккаунт")) {
            if let user = viewModel.authManager.currentUser {
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
            } else {
                Text("Не авторизован")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var apiKeySection: some View {
        Section(header: Text("API ключ провайдера")) {
            // Поле ввода API ключа
            Group {
                if viewModel.isApiKeyVisible {
                    TextField("Введите ключ", text: $viewModel.chatService.userApiKey)
                } else {
                    SecureField("Введите ключ", text: $viewModel.chatService.userApiKey)
                }
            }
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.system(.body, design: .monospaced))
            
            // Переключатель видимости ключа
            Toggle("Показать ключ", isOn: $viewModel.isApiKeyVisible)
                .toggleStyle(SwitchToggleStyle(tint: .green))
            
            // Кнопка очистки ключа
            if !viewModel.chatService.userApiKey.isEmpty {
                Button(role: .destructive) {
                    viewModel.chatService.userApiKey = ""
                } label: {
                    Label("Очистить ключ", systemImage: "trash")
                }
            }
            
            // Описание
            Text("Если указать API ключ (например, OpenAI или совместимый), ответы будут генерироваться через удалённую модель. Без ключа применяется локальная модель HalalAI.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    private var remoteModelSection: some View {
        Section(header: Text("Удалённая модель")) {
            // Выбор модели
            if !viewModel.chatService.availableModels.isEmpty {
                Picker("Выберите модель", selection: $viewModel.chatService.remoteModel) {
                    ForEach(viewModel.chatService.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .font(.system(.body, design: .monospaced))
                
                Text("Доступно \(viewModel.chatService.availableModels.count) моделей. По умолчанию: \(viewModel.chatService.defaultRemoteModel)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                TextField("remote_model (например, xiaomi/mimo-v2-flash:free)", text: $viewModel.chatService.remoteModel)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(.system(.body, design: .monospaced))
                
                Text("Введите имя модели вручную. Список пока не загружен.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            // Слайдер max_tokens
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("max_tokens")
                    Spacer()
                    Text("\(Int(viewModel.maxTokensSlider))")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                Slider(
                    value: $viewModel.maxTokensSlider,
                    in: 16...6144,
                    step: 16,
                    label: { Text("max_tokens") },
                    minimumValueLabel: {
                        Text("16")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    },
                    maximumValueLabel: {
                        Text("6144")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                
                Text("Лимит токенов для генерации. Сервер принимает до 6144.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            // Кнопка обновления списка моделей
            Button("Обновить список моделей") {
                Task {
                    await viewModel.chatService.loadModels()
                }
            }
            .font(.footnote)
        }
    }
    
    private var dataSourcesSection: some View {
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
    }
    
    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.authManager.logout()
            } label: {
                HStack {
                    Spacer()
                    Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                    Spacer()
                }
            }
        }
    }
}
