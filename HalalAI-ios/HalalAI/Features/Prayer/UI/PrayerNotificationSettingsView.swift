//
//  PrayerNotificationSettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import SwiftUI
import UserNotifications

struct PrayerNotificationSettingsView: View {
    @State private var viewModel: ViewModel
    @Environment(Coordinator.self) var coordinator
    @Environment(LanguageStore.self) private var lang

    init(
        settingsStore: PrayerSettingsStore,
        notificationService: PrayerNotificationService,
        locationService: LocationService
    ) {
        _viewModel = State(
            initialValue: ViewModel(
                settingsStore: settingsStore,
                notificationService: notificationService,
                locationService: locationService
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel
        Form {
            calculationSection
            anglesSection
            madhabSection
            notificationSection
            testSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.greenBackground.ignoresSafeArea())
        .navigationTitle(lang.t("prayer.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(lang.t("common.back"), systemImage: "arrow.left") {
                    coordinator.dismiss()
                }
                .labelStyle(.iconOnly)
            }
        }
        .task {
            await vm.onAppear()
        }
    }

    // MARK: - Sections

    private var calculationSection: some View {
        Section(header: Text(lang.t("prayer.settings.method_section"))) {
            Picker(lang.t("prayer.settings.method_picker"), selection: $viewModel.settings.calculationMethod) {
                ForEach(PrayerCalculationMethod.allCases, id: \.self) { method in
                    Text(method.localizedName).tag(method)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.settings.calculationMethod) { _, _ in
                viewModel.onSettingsChanged()
            }

            Text(lang.t("prayer.settings.method_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var anglesSection: some View {
        Section(header: Text(lang.t("prayer.settings.angles_section"))) {
            AngleStepper(
                label: lang.t("prayer.name.fajr"),
                defaultAngle: viewModel.settings.calculationMethod.fajrAngle,
                value: Binding(
                    get: { viewModel.settings.customFajrAngle ?? viewModel.settings.calculationMethod.fajrAngle },
                    set: { viewModel.settings.customFajrAngle = $0; viewModel.onSettingsChanged() }
                ),
                isCustom: viewModel.settings.customFajrAngle != nil,
                onReset: { viewModel.settings.customFajrAngle = nil; viewModel.onSettingsChanged() },
                resetLabel: lang.t("prayer.settings.reset"),
                defaultLabel: lang.t("prayer.settings.default")
            )
            AngleStepper(
                label: lang.t("prayer.name.isha"),
                defaultAngle: viewModel.settings.calculationMethod.ishaAngle,
                value: Binding(
                    get: { viewModel.settings.customIshaAngle ?? viewModel.settings.calculationMethod.ishaAngle },
                    set: { viewModel.settings.customIshaAngle = $0; viewModel.onSettingsChanged() }
                ),
                isCustom: viewModel.settings.customIshaAngle != nil,
                onReset: { viewModel.settings.customIshaAngle = nil; viewModel.onSettingsChanged() },
                resetLabel: lang.t("prayer.settings.reset"),
                defaultLabel: lang.t("prayer.settings.default")
            )
            Text(lang.t("prayer.settings.angles_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var madhabSection: some View {
        Section(header: Text(lang.t("prayer.settings.madhab_section"))) {
            Picker(lang.t("prayer.settings.madhab_picker"), selection: $viewModel.settings.madhab) {
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
        Section(header: Text(lang.t("prayer.settings.notifications_section"))) {
            if viewModel.notificationsAuthorized == false {
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t("prayer.settings.notifications_disabled"))
                            .fontWeight(.medium)
                        Text(lang.t("prayer.settings.notifications_allow"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button(lang.t("prayer.settings.open_settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundStyle(Color.greenForeground)
            }

            ForEach(Prayer.notifiablePrayers, id: \.self) { prayer in
                PrayerNotificationRow(
                    prayer: prayer,
                    prayerName: lang.t("prayer.name.\(prayer.rawValue)"),
                    setting: viewModel.bindingSetting(for: prayer),
                    onChanged: viewModel.onSettingsChanged,
                    offsetOptions: [
                        (lang.t("prayer.settings.at_prayer"), 0),
                        (lang.t("prayer.settings.before_5"), 5),
                        (lang.t("prayer.settings.before_10"), 10),
                        (lang.t("prayer.settings.before_15"), 15),
                        (lang.t("prayer.settings.before_30"), 30),
                    ],
                    whenNotifyLabel: lang.t("prayer.settings.when_notify")
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
                    Label(lang.t("prayer.settings.test_button"), systemImage: "bell.badge.waveform")
                    Spacer()
                }
            }
            .foregroundStyle(Color.greenForeground)
            .disabled(viewModel.notificationsAuthorized == false)

            Text(lang.t("prayer.settings.test_hint"))
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
    var resetLabel: String = "Reset"
    var defaultLabel: String = "default"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                if isCustom {
                    Button(resetLabel, action: onReset)
                        .font(.caption)
                        .foregroundStyle(Color.greenForeground)
                } else {
                    Text(defaultLabel)
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
                        Text("\(value.formatted(.number.precision(.fractionLength(1))))°")
                            .monospacedDigit()
                            .fontWeight(isCustom ? .semibold : .regular)
                            .foregroundStyle(isCustom ? Color.greenForeground : .primary)
                        if !isCustom {
                            Text("(\(defaultLabel) \(defaultAngle.formatted(.number.precision(.fractionLength(1))))°)")
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
    let prayerName: String
    @Binding var setting: PrayerNotificationSetting
    let onChanged: () -> Void
    let offsetOptions: [(label: String, minutes: Int)]
    let whenNotifyLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $setting.isEnabled) {
                Label(prayerName, systemImage: prayer.systemImage)
                    .foregroundStyle(.primary)
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            .onChange(of: setting.isEnabled) { _, _ in onChanged() }

            if setting.isEnabled {
                Picker(whenNotifyLabel, selection: $setting.offsetMinutes) {
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
            if notificationsAuthorized == nil {
                let granted = await notificationService.requestAuthorization()
                notificationsAuthorized = granted
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
