//
//  PrayerNotificationSettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import SwiftUI
import UserNotifications

struct PrayerNotificationSettingsView: View {
    @Bindable var viewModel: ViewModel
    @Environment(Coordinator.self) var coordinator

    var body: some View {
        Form {
            calculationSection
            anglesSection
            madhabSection
            notificationSection
            testSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.greenBackground.ignoresSafeArea())
        .navigationTitle("Время намаза")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "arrow.left")
                    .onTapGesture {
                        coordinator.dismiss()
                    }
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Sections

    private var calculationSection: some View {
        Section(header: Text("Метод расчёта")) {
            Picker("Метод", selection: $viewModel.settings.calculationMethod) {
                ForEach(PrayerCalculationMethod.allCases, id: \.self) { method in
                    Text(method.localizedName).tag(method)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.settings.calculationMethod) { _, _ in
                viewModel.onSettingsChanged()
            }

            Text("Выберите метод расчёта в соответствии с вашим регионом или предпочтениями.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var anglesSection: some View {
        Section(header: Text("Углы Фаджр и Иша")) {
            AngleStepper(
                label: "Фаджр",
                defaultAngle: viewModel.settings.calculationMethod.fajrAngle,
                value: Binding(
                    get: { viewModel.settings.customFajrAngle ?? viewModel.settings.calculationMethod.fajrAngle },
                    set: { viewModel.settings.customFajrAngle = $0; viewModel.onSettingsChanged() }
                ),
                isCustom: viewModel.settings.customFajrAngle != nil,
                onReset: { viewModel.settings.customFajrAngle = nil; viewModel.onSettingsChanged() }
            )
            AngleStepper(
                label: "Иша",
                defaultAngle: viewModel.settings.calculationMethod.ishaAngle,
                value: Binding(
                    get: { viewModel.settings.customIshaAngle ?? viewModel.settings.calculationMethod.ishaAngle },
                    set: { viewModel.settings.customIshaAngle = $0; viewModel.onSettingsChanged() }
                ),
                isCustom: viewModel.settings.customIshaAngle != nil,
                onReset: { viewModel.settings.customIshaAngle = nil; viewModel.onSettingsChanged() }
            )
            Text("Угол солнца ниже горизонта (градусы). По умолчанию — значение выбранного метода.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var madhabSection: some View {
        Section(header: Text("Мазхаб (время Аср)")) {
            Picker("Мазхаб", selection: $viewModel.settings.madhab) {
                ForEach(Madhab.allCases, id: \.self) { madhab in
                    Text(madhab.localizedName).tag(madhab)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.settings.madhab) { _, _ in
                viewModel.onSettingsChanged()
            }
        }
    }

    private var notificationSection: some View {
        Section(header: Text("Уведомления")) {
            if viewModel.notificationsAuthorized == false {
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Уведомления отключены")
                            .fontWeight(.medium)
                        Text("Разрешите в Настройках → HalalAI → Уведомления")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Открыть настройки") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundStyle(Color.greenForeground)
            }

            ForEach(Prayer.notifiablePrayers, id: \.self) { prayer in
                PrayerNotificationRow(
                    prayer: prayer,
                    setting: viewModel.bindingSetting(for: prayer),
                    onChanged: viewModel.onSettingsChanged
                )
            }
        }
    }

    private var testSection: some View {
        Section {
            Button {
                Task { await viewModel.sendTestNotification() }
            } label: {
                HStack {
                    Spacer()
                    Label("Тестовое уведомление (через 5 сек)", systemImage: "bell.badge.waveform")
                    Spacer()
                }
            }
            .foregroundStyle(Color.greenForeground)
            .disabled(viewModel.notificationsAuthorized == false)

            Text("Отправит уведомление через 5 секунд для проверки работы.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Angle Stepper

private struct AngleStepper: View {
    let label: String
    let defaultAngle: Double
    @Binding var value: Double
    let isCustom: Bool
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                if isCustom {
                    Button("Сбросить", action: onReset)
                        .font(.caption)
                        .foregroundStyle(Color.greenForeground)
                } else {
                    Text("по умолчанию")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Stepper(
                    value: $value,
                    in: 10.0...25.0,
                    step: 0.5
                ) {
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f°", value))
                            .monospacedDigit()
                            .fontWeight(isCustom ? .semibold : .regular)
                            .foregroundStyle(isCustom ? Color.greenForeground : .primary)
                        if !isCustom {
                            Text("(по умолчанию \(String(format: "%.1f°", defaultAngle)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Prayer Notification Row

private struct PrayerNotificationRow: View {
    let prayer: Prayer
    @Binding var setting: PrayerNotificationSetting
    let onChanged: () -> Void

    private let offsetOptions: [(label: String, minutes: Int)] = [
        ("Ровно в намаз", 0),
        ("За 5 минут",    5),
        ("За 10 минут",  10),
        ("За 15 минут",  15),
        ("За 30 минут",  30),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $setting.isEnabled) {
                Label(prayer.localizedName, systemImage: prayer.systemImage)
                    .foregroundStyle(.primary)
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            .onChange(of: setting.isEnabled) { _, _ in onChanged() }

            if setting.isEnabled {
                Picker("Когда уведомлять", selection: $setting.offsetMinutes) {
                    ForEach(offsetOptions, id: \.minutes) { option in
                        Text(option.label).tag(option.minutes)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: setting.offsetMinutes) { _, _ in onChanged() }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel

extension PrayerNotificationSettingsView {
    @Observable
    @MainActor
    final class ViewModel {
        var settings: PrayerSettings
        var notificationsAuthorized: Bool? = nil

        private let settingsStore: PrayerSettingsStore
        private let notificationService: PrayerNotificationService
        private let locationService: LocationService

        init(
            settingsStore: PrayerSettingsStore,
            notificationService: PrayerNotificationService,
            locationService: LocationService
        ) {
            self.settingsStore = settingsStore
            self.notificationService = notificationService
            self.locationService = locationService
            self.settings = settingsStore.settings
        }

        func onAppear() async {
            await checkNotificationStatus()
            if notificationsAuthorized == false {
                notificationsAuthorized = await notificationService.requestAuthorization()
            }
        }

        func onSettingsChanged() {
            settingsStore.settings = settings
            Task {
                guard let location = locationService.currentLocation else { return }
                await notificationService.scheduleNotifications(settings: settings, location: location)
            }
        }

        func sendTestNotification() async {
            await notificationService.sendTestNotification()
        }

        func bindingSetting(for prayer: Prayer) -> Binding<PrayerNotificationSetting> {
            Binding(
                get: { self.settings.notificationSetting(for: prayer) },
                set: { self.settings.setNotification($0, for: prayer) }
            )
        }

        private func checkNotificationStatus() async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                notificationsAuthorized = true
            case .denied:
                notificationsAuthorized = false
            case .notDetermined:
                notificationsAuthorized = nil
            @unknown default:
                notificationsAuthorized = nil
            }
        }
    }
}
