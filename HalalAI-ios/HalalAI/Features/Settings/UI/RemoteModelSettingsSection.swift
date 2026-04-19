//
//  RemoteModelSettingsSection.swift
//  HalalAI
//
//  Extracted from SettingsView.swift
//

import SwiftUI

/// Секция настроек удалённой модели: выбор модели, max_tokens, temperature, RAG.
struct RemoteModelSettingsSection: View {
    @Binding var remoteModel: String
    @Binding var useRag: Bool
    @Binding var maxTokensSlider: Double
    @Binding var temperatureSlider: Double
    @Binding var useCustomModel: Bool
    var availableModels: [String]
    var defaultRemoteModel: String
    var onRefreshModels: () -> Void

    var body: some View {
        Section(header: Text("Удалённая модель")) {
            modelPickerContent
            maxTokensContent
            temperatureContent
            ragToggleContent
            refreshButton
        }
    }

    // MARK: - Model Picker

    @ViewBuilder
    private var modelPickerContent: some View {
        if !availableModels.isEmpty {
            Picker("Выберите модель", selection: $remoteModel) {
                ForEach(availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(.menu)
            .font(.system(.body, design: .monospaced))

            Text("Доступно \(availableModels.count) моделей. По умолчанию: \(defaultRemoteModel)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle("Использовать custom модель", isOn: $useCustomModel)
                .toggleStyle(SwitchToggleStyle(tint: .green))

            if useCustomModel {
                TextField(
                    "Введите имя модели (например, meta-llama/llama-3.3-70b-instruct:free)",
                    text: $remoteModel
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.system(.body, design: .monospaced))

                Text("Укажите имя модели в формате провайдера/модель.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            TextField(
                "Введите имя модели (например, meta-llama/llama-3.3-70b-instruct:free)",
                text: $remoteModel
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.system(.body, design: .monospaced))

            Text("Введите имя модели вручную. Список пока не загружен.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Max Tokens

    private var maxTokensContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("max_tokens")
                Spacer()
                Text("\(Int(maxTokensSlider))")
                    .foregroundStyle(.secondary)
                    .font(.system(.body, design: .monospaced))
            }

            Slider(
                value: $maxTokensSlider,
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
    }

    // MARK: - Temperature

    private var temperatureContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("temperature")
                Spacer()
                Text(temperatureSlider, format: .number.precision(.fractionLength(2)))
                    .foregroundStyle(.secondary)
                    .font(.system(.body, design: .monospaced))
            }

            Slider(
                value: $temperatureSlider,
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
    }

    // MARK: - RAG Toggle

    private var ragToggleContent: some View {
        Group {
            Toggle("Использовать RAG (семантический поиск)", isOn: $useRag)
                .toggleStyle(SwitchToggleStyle(tint: .green))

            Text("RAG извлекает релевантные аяты из Корана для контекста. Выключите для ответов без контекста.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Refresh

    private var refreshButton: some View {
        Button("Обновить список моделей", action: onRefreshModels)
            .font(.footnote)
    }
}
