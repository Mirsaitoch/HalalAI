//
//  SettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel: ViewModel
    @Environment(LanguageStore.self) private var lang

    init(chatService: ChatService, authManager: AuthManager) {
        _viewModel = State(initialValue: ViewModel(chatService: chatService, authManager: authManager))
    }

    var body: some View {
        @Bindable var vm = viewModel
        VStack {
            Form {
                languageSection
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
            .navigationTitle(lang.t("settings.title"))
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

    private var languageSection: some View {
        Section(header: Text(lang.t("settings.language"))) {
            @Bindable var ls = lang
            Picker(lang.t("settings.language"), selection: $ls.currentLanguage) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var accountSection: some View {
        Section(header: Text(lang.t("settings.account"))) {
            if let user = viewModel.authManager.currentUser {
                HStack {
                    Text(lang.t("auth.login.email"))
                    Spacer()
                    Text(user.email)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(lang.t("settings.not_authorized"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var apiKeySection: some View {
        @Bindable var vm = viewModel
        return Section(header: Text(lang.t("settings.api_key"))) {
            Group {
                if vm.isApiKeyVisible {
                    TextField(lang.t("settings.api_key.placeholder"), text: Binding(
                        get: { vm.chatService.userApiKey },
                        set: { vm.chatService.userApiKey = $0 }
                    ))
                } else {
                    SecureField(lang.t("settings.api_key.placeholder"), text: Binding(
                        get: { vm.chatService.userApiKey },
                        set: { vm.chatService.userApiKey = $0 }
                    ))
                }
            }
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.system(.body, design: .monospaced))

            Toggle(lang.t("settings.api_key.show"), isOn: $vm.isApiKeyVisible)
                .toggleStyle(SwitchToggleStyle(tint: .green))

            if !vm.chatService.userApiKey.isEmpty {
                Button(role: .destructive) {
                    vm.chatService.userApiKey = ""
                } label: {
                    Label(lang.t("settings.api_key.clear"), systemImage: "trash")
                }
            }

            Text(lang.t("settings.api_key.hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var dataSourcesSection: some View {
        Section(header: Text(lang.t("settings.data_sources"))) {
            Text(lang.t("settings.rag_description"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)

            if let url = URL(string: "https://xn----8sbemuhsaeiwd9h5a9c.xn--p1ai/chitat-koran-na-russkom/elmir-kuliev/") {
                Link(lang.t("settings.open_source"), destination: url)
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
                    Label(lang.t("settings.logout"), systemImage: "rectangle.portrait.and.arrow.right")
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
                Label(lang.t("settings.login"), systemImage: "person.crop.circle")
                    .frame(alignment: .leading)
            }
            .foregroundStyle(.darkGreen)
        } header: {
            Text(lang.t("settings.account"))
        }
    }
}
