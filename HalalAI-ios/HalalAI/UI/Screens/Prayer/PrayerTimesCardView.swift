//
//  PrayerTimesCardView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import SwiftUI
import CoreLocation

struct PrayerTimesCardView: View {
    @Environment(Coordinator.self) var coordinator
    var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader
            Divider().padding(.horizontal)
            if let times = viewModel.todayTimes {
                prayerList(times: times)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.tabBar)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            viewModel.refresh()
        }
        .onChange(of: viewModel.locationService.currentLocation?.coordinate.latitude) { _, _ in
            viewModel.recalculate()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var cardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Время намаза")
                    .font(.headline)
                    .foregroundStyle(.primary)

                switch viewModel.locationService.authorizationStatus {
                case .notDetermined:
                    Button {
                        viewModel.locationService.requestLocation()
                    } label: {
                        Label("Разрешить геолокацию", systemImage: "location")
                            .font(.subheadline)
                            .foregroundStyle(Color.greenForeground)
                    }
                case .denied, .restricted:
                    Text("Нет доступа к геолокации")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                case .authorizedWhenInUse, .authorizedAlways:
                    if let (prayer, time) = viewModel.nextPrayer {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Следующий: \(prayer.localizedName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                Text(time, format: .dateTime.hour().minute())
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.greenForeground)
                                TimelineView(.periodic(from: .now, by: 60)) { _ in
                                    Text(countdown(to: time))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                }
                            }
                        }
                    } else if viewModel.todayTimes == nil {
                        Text("Определяем местоположение…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Все намазы пройдены")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    EmptyView()
                }
            }

            Spacer()

            Button {
                coordinator.nextStep(step: .Home(.prayerSettings))
            } label: {
                Image(systemName: "bell.badge")
                    .font(.title3)
                    .foregroundStyle(Color.greenForeground)
                    .padding(8)
                    .background(Circle().fill(Color.greenForeground.opacity(0.12)))
            }
        }
        .padding()
    }

    // MARK: - Prayer List

    @ViewBuilder
    private func prayerList(times: DailyPrayerTimes) -> some View {
        VStack(spacing: 0) {
            ForEach(Prayer.allCases, id: \.self) { prayer in
                PrayerRowView(
                    prayer: prayer,
                    time: times.time(for: prayer),
                    isNext: viewModel.nextPrayer?.0 == prayer
                )
                if prayer != Prayer.allCases.last {
                    Divider().padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Countdown

    private func countdown(to date: Date) -> String {
        let diff = Int(date.timeIntervalSinceNow)
        guard diff > 0 else { return "" }
        let h = diff / 3600
        let m = (diff % 3600) / 60
        if h > 0 {
            return "через \(h)ч \(m)м"
        } else {
            return "через \(m)м"
        }
    }
}

// MARK: - Prayer Row

private struct PrayerRowView: View {
    let prayer: Prayer
    let time: Date
    let isNext: Bool

    var body: some View {
        HStack {
            Image(systemName: prayer.systemImage)
                .frame(width: 24)
                .foregroundStyle(isNext ? Color.greenForeground : .secondary)

            Text(prayer.localizedName)
                .foregroundStyle(isNext ? .primary : .secondary)
                .fontWeight(isNext ? .semibold : .regular)

            Spacer()

            Text(time, format: .dateTime.hour().minute())
                .foregroundStyle(isNext ? Color.greenForeground : .secondary)
                .fontWeight(isNext ? .semibold : .regular)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(isNext ? Color.greenForeground.opacity(0.08) : Color.clear)
    }
}

// MARK: - ViewModel

extension PrayerTimesCardView {
    @Observable
    @MainActor
    final class ViewModel {
        let locationService: LocationService
        private let prayerTimeService: PrayerTimeService
        private let settingsStore: PrayerSettingsStore

        var todayTimes: DailyPrayerTimes?
        var nextPrayer: (Prayer, Date)?

        init(
            locationService: LocationService,
            prayerTimeService: PrayerTimeService,
            settingsStore: PrayerSettingsStore
        ) {
            self.locationService = locationService
            self.prayerTimeService = prayerTimeService
            self.settingsStore = settingsStore
        }

        func refresh() {
            locationService.requestLocation()
            recalculate()
        }

        func recalculate() {
            guard let loc = locationService.currentLocation else { return }
            let settings = settingsStore.settings
            todayTimes = prayerTimeService.calculateTimes(
                for: Date(),
                location: loc,
                settings: settings
            )
            if let times = todayTimes {
                nextPrayer = prayerTimeService.nextPrayer(from: times)
            }
        }
    }
}
