//
//  SettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel: ViewModel

    init(chatService: ChatService, authManager: AuthManager) {
        _viewModel = State(initialValue: ViewModel(chatService: chatService, authManager: authManager))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        VStack {
            Form {
                if vm.authManager.isGuest {
                    guestLoginSection
                } else {
                    accountSection
                    apiKeySection
                    remoteModelSection
                    dataSourcesSection
                    logoutSection
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.greenBackground.ignoresSafeArea())
        }
        .background(Color.greenBackground.ignoresSafeArea())
        .onAppear {
            vm.maxTokensSlider = Double(vm.chatService.maxTokens)
            vm.temperatureSlider = vm.chatService.temperature
            Task {
                await vm.chatService.loadModels()
            }
        }
        .onChange(of: vm.maxTokensSlider) { _, newValue in
            vm.chatService.maxTokens = Int(newValue)
        }
        .onChange(of: vm.temperatureSlider) { _, newValue in
            vm.chatService.temperature = newValue
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
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Email")
                    Spacer()
                    Text(user.email)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Не авторизован")
                    .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
    
    private var remoteModelSection: some View {
        Section(header: Text("Удалённая модель")) {
            // Выбор модели из списка или custom ввод
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
                    .foregroundStyle(.secondary)

                // Toggle для custom модели
                Toggle("Использовать custom модель", isOn: $viewModel.useCustomModel)
                    .toggleStyle(SwitchToggleStyle(tint: .green))

                if viewModel.useCustomModel {
                    TextField("Введите имя модели (например, meta-llama/llama-3.3-70b-instruct:free)", text: $viewModel.chatService.remoteModel)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))

                    Text("Укажите имя модели в формате провайдера/модель.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                TextField("Введите имя модели (например, meta-llama/llama-3.3-70b-instruct:free)", text: $viewModel.chatService.remoteModel)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(.system(.body, design: .monospaced))

                Text("Введите имя модели вручную. Список пока не загружен.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // Слайдер max_tokens
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("max_tokens")
                    Spacer()
                    Text("\(Int(viewModel.maxTokensSlider))")
                        .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)
                    },
                    maximumValueLabel: {
                        Text("6144")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                )

                Text("Лимит токенов для генерации. Сервер принимает до 6144.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Слайдер temperature
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("temperature")
                    Spacer()
                    Text(viewModel.temperatureSlider, format: .number.precision(.fractionLength(2)))
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }

                Slider(
                    value: $viewModel.temperatureSlider,
                    in: 0.0...2.0,
                    step: 0.1,
                    label: { Text("temperature") },
                    minimumValueLabel: {
                        Text("0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    },
                    maximumValueLabel: {
                        Text("2.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                )

                Text("Контролирует случайность ответов. 0 = детерминированно, 2.0 = максимально случайно.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Toggle для RAG
            Toggle("Использовать RAG (семантический поиск)", isOn: $viewModel.chatService.useRag)
                .toggleStyle(SwitchToggleStyle(tint: .green))

            Text("RAG извлекает релевантные аяты из Корана для контекста. Выключите для ответов без контекста.")
                .font(.footnote)
                .foregroundStyle(.secondary)

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
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            
            if let url = URL(string: "https://xn----8sbemuhsaeiwd9h5a9c.xn--p1ai/chitat-koran-na-russkom/elmir-kuliev/") {
                Link("Открыть источник", destination: url)
                    .font(.footnote)
                    .foregroundStyle(.blue)
            }
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

    private var guestLoginSection: some View {
        Section {
            Button {
                viewModel.authManager.logout()
            } label: {
                Label("Войти или зарегистрироваться", systemImage: "person.crop.circle")
                    .frame(alignment: .leading)
            }
            .foregroundStyle(.darkGreen)
        } header: {
            Text("Аккаунт")
        }
    }
}
