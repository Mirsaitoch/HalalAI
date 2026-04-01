//
//  PrayerTimesCardView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import SwiftUI
import Combine

struct PrayerTimesCardView: View {
    @Environment(Coordinator.self) var coordinator
    var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader
            dayPickerRow
            Divider().padding(.horizontal)
            if let times = viewModel.displayedTimes {
                prayerList(times: times)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.greenForeground)
        )
        .onAppear {
            viewModel.refresh()
        }
        .onChange(of: viewModel.locationService.currentLocation?.coordinate.latitude) { _, _ in
            viewModel.recalculate()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            viewModel.recalculate()
        }
    }

    @ViewBuilder
    private var dayPickerRow: some View {
        switch viewModel.locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if viewModel.displayedTimes != nil {
                HStack {
                    Button {
                        viewModel.shiftDisplayedDay(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .frame(width: 36, height: 32)
                    }
                    .disabled(!viewModel.canShiftToPreviousDay)
                    .opacity(viewModel.canShiftToPreviousDay ? 1 : 0.35)

                    Spacer()

                    Text(viewModel.displayedDayTitle)
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Button {
                        viewModel.shiftDisplayedDay(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .frame(width: 36, height: 32)
                    }
                    .disabled(!viewModel.canShiftToNextDay)
                    .opacity(viewModel.canShiftToNextDay ? 1 : 0.35)
                }
                .foregroundStyle(.darkGreen)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var cardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Время намаза")
                    .font(.headline)
                    .foregroundStyle(.darkGreen)

                switch viewModel.locationService.authorizationStatus {
                case .notDetermined:
                    Button {
                        viewModel.locationService.requestLocation()
                    } label: {
                        Label("Разрешить геолокацию", systemImage: "location")
                            .font(.subheadline)
                            .foregroundStyle(.darkGreen)
                    }
                case .denied, .restricted:
                    Text("Нет доступа к геолокации")
                        .font(.subheadline)
                        .foregroundStyle(.darkGreen)
                case .authorizedWhenInUse, .authorizedAlways:
                    if let (prayer, time) = viewModel.nextPrayer {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Следующий: \(prayer.localizedName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                Text(time, format: .dateTime.hour().minute())
                                    .font(.title2.bold())
                                    .foregroundStyle(.darkGreen)
                                TimelineView(.periodic(from: .now, by: 60)) { _ in
                                    Text(countdown(to: time))
                                        .font(.caption)
                                        .foregroundStyle(.darkGreen)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                }
                            }
                        }
                    } else if viewModel.displayedTimes == nil {
                        Text("Определяем местоположение…")
                            .font(.subheadline)
                            .foregroundStyle(.darkGreen)
                    } else {
                        Text("Все намазы прошли")
                            .font(.subheadline)
                            .foregroundStyle(.darkGreen)
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
                    .foregroundStyle(.darkGreen)
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
                    isNext: viewModel.isNextPrayerRow(prayer: prayer, time: times.time(for: prayer))
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
                .foregroundStyle(isNext ? .darkGreen : .secondary)

            Text(prayer.localizedName)
                .foregroundStyle(isNext ? .primary : .secondary)
                .fontWeight(isNext ? .semibold : .regular)

            Spacer()

            Text(time, format: .dateTime.hour().minute())
                .foregroundStyle(isNext ? .primary : .secondary)
                .fontWeight(isNext ? .semibold : .regular)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(isNext ? Color.greenForeground.opacity(0.08) : Color.clear)
    }
}
