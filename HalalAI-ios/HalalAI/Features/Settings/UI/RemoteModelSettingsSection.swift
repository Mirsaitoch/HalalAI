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
    @Environment(LanguageStore.self) private var lang

    var body: some View {
        Section(header: Text(lang.t("model.section"))) {
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
            Picker(lang.t("model.select"), selection: $remoteModel) {
                ForEach(availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(.menu)
            .font(.system(.body, design: .monospaced))

            Text("\(availableModels.count) \(lang.t("model.select")). \(defaultRemoteModel)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle(lang.t("model.custom"), isOn: $useCustomModel)
                .toggleStyle(SwitchToggleStyle(tint: .green))

            if useCustomModel {
                TextField(
                    lang.t("model.placeholder"),
                    text: $remoteModel
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.system(.body, design: .monospaced))

                Text(lang.t("model.format_hint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            TextField(
                lang.t("model.placeholder"),
                text: $remoteModel
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.system(.body, design: .monospaced))

            Text(lang.t("model.manual_hint"))
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

            Text(lang.t("model.token_hint"))
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

            Text(lang.t("model.temperature_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - RAG Toggle

    private var ragToggleContent: some View {
        Group {
            Toggle(lang.t("model.rag"), isOn: $useRag)
                .toggleStyle(SwitchToggleStyle(tint: .green))

            Text(lang.t("model.rag_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Refresh

    private var refreshButton: some View {
        Button(lang.t("model.refresh"), action: onRefreshModels)
            .font(.footnote)
    }
}
