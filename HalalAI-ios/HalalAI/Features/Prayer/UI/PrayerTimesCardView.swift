//
//  PrayerTimesCardView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import SwiftUI

struct PrayerTimesCardView: View {
    @Environment(Coordinator.self) var coordinator
    @Environment(LanguageStore.self) private var lang
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

    // MARK: - Day title (localized)

    private var localizedDayTitle: String {
        let offset = viewModel.effectiveDayOffset
        switch offset {
        case 0: return lang.t("prayer.today")
        case 1: return lang.t("prayer.tomorrow")
        case -1: return lang.t("prayer.yesterday")
        default:
            let start = Calendar(identifier: .gregorian).startOfDay(for: Date.now)
            guard let day = Calendar(identifier: .gregorian).date(byAdding: .day, value: offset, to: start) else { return "" }
            return day.formatted(.dateTime.day().month(.wide).weekday(.wide).locale(lang.currentLanguage.locale)).capitalized
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

                    Text(localizedDayTitle)
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
                Text(lang.t("prayer.title"))
                    .font(.headline)
                    .foregroundStyle(.darkGreen)

                switch viewModel.locationService.authorizationStatus {
                case .notDetermined:
                    Button {
                        viewModel.locationService.requestLocation()
                    } label: {
                        Label(lang.t("prayer.allow_location"), systemImage: "location")
                            .font(.subheadline)
                            .foregroundStyle(.darkGreen)
                    }
                case .denied, .restricted:
                    Text(lang.t("prayer.no_location"))
                        .font(.subheadline)
                        .foregroundStyle(.darkGreen)
                case .authorizedWhenInUse, .authorizedAlways:
                    if let (prayer, time) = viewModel.nextPrayer {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t("prayer.next") + lang.t("prayer.name.\(prayer.rawValue)"))
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
                        Text(lang.t("prayer.determining_location"))
                            .font(.subheadline)
                            .foregroundStyle(.darkGreen)
                    } else {
                        Text(lang.t("prayer.all_passed"))
                            .font(.subheadline)
                            .foregroundStyle(.darkGreen)
                    }
                @unknown default:
                    EmptyView()
                }
            }

            Spacer()

            Button(lang.t("prayer.notification_settings"), systemImage: "bell.badge") {
                coordinator.nextStep(step: .home(.prayerSettings))
            }
            .font(.title3)
            .foregroundStyle(.darkGreen)
            .labelStyle(.iconOnly)
            .padding(8)
            .background(Circle().fill(Color.greenForeground.opacity(0.12)))
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
                    prayerName: lang.t("prayer.name.\(prayer.rawValue)"),
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
        if lang.currentLanguage == .russian {
            return h > 0 ? "через \(h)ч \(m)м" : "через \(m)м"
        } else {
            return h > 0 ? "in \(h)h \(m)m" : "in \(m)m"
        }
    }
}

// MARK: - Prayer Row

private struct PrayerRowView: View {
    let prayer: Prayer
    let prayerName: String
    let time: Date
    let isNext: Bool

    var body: some View {
        HStack {
            Image(systemName: prayer.systemImage)
                .frame(width: 24)
                .foregroundStyle(isNext ? .darkGreen : .secondary)

            Text(prayerName)
                .foregroundStyle(isNext ? .darkGreen : .secondary)
                .fontWeight(isNext ? .semibold : .regular)

            Spacer()

            Text(time, format: .dateTime.hour().minute())
                .foregroundStyle(isNext ? .darkGreen : .secondary)
                .fontWeight(isNext ? .semibold : .regular)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(isNext ? Color.greenForeground.opacity(0.08) : Color.clear)
    }
}
