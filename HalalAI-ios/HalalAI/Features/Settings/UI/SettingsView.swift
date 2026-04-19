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
                    RemoteModelSettingsSection(
                        remoteModel: Binding(
                            get: { vm.chatService.remoteModel },
                            set: { vm.chatService.remoteModel = $0 }
                        ),
                        useRag: Binding(
                            get: { vm.chatService.useRag },
                            set: { vm.chatService.useRag = $0 }
                        ),
                        maxTokensSlider: $vm.maxTokensSlider,
                        temperatureSlider: $vm.temperatureSlider,
                        useCustomModel: $vm.useCustomModel,
                        availableModels: vm.chatService.availableModels,
                        defaultRemoteModel: vm.chatService.defaultRemoteModel,
                        onRefreshModels: {
                            Task { await vm.chatService.loadModels() }
                        }
                    )
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
        @Bindable var vm = viewModel
        return Section(header: Text("API ключ провайдера")) {
            Group {
                if vm.isApiKeyVisible {
                    TextField("Введите ключ", text: Binding(
                        get: { vm.chatService.userApiKey },
                        set: { vm.chatService.userApiKey = $0 }
                    ))
                } else {
                    SecureField("Введите ключ", text: Binding(
                        get: { vm.chatService.userApiKey },
                        set: { vm.chatService.userApiKey = $0 }
                    ))
                }
            }
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.system(.body, design: .monospaced))

            Toggle("Показать ключ", isOn: $vm.isApiKeyVisible)
                .toggleStyle(SwitchToggleStyle(tint: .green))

            if !vm.chatService.userApiKey.isEmpty {
                Button(role: .destructive) {
                    vm.chatService.userApiKey = ""
                } label: {
                    Label("Очистить ключ", systemImage: "trash")
                }
            }

            Text("Если указать API ключ (например, OpenAI или совместимый), ответы будут генерироваться через удалённую модель. Без ключа применяется локальная модель HalalAI.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
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
