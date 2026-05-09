//
//  PrayerTimesCardViewModelTests.swift
//  HalalAITests
//

import Foundation
import CoreLocation
import Testing
@testable import HalalAI

@MainActor
struct PrayerTimesCardViewModelTests {

    // MARK: - displayedDayTitle

    @Test("displayedDayTitle returns 'Сегодня' when day offset is 0")
    func todayTitle() {
        let (vm, prayerService, _) = makeSUT()
        let now = Date()
        let times = makeTimes(base: now, future: true)
        prayerService.calculateResult = times
        prayerService.nextPrayerResult = (.dhuhr, now.addingTimeInterval(3600))

        vm.recalculate()

        #expect(vm.displayedDayTitle == "Сегодня")
    }

    @Test("displayedDayTitle returns 'Завтра' when no more prayers today")
    func tomorrowTitle() {
        let (vm, prayerService, _) = makeSUT()
        let now = Date()
        let times = makeTimes(base: now, future: false)
        prayerService.calculateResult = times
        prayerService.nextPrayerResult = nil // all passed

        vm.recalculate()

        #expect(vm.displayedDayTitle == "Завтра")
    }

    // MARK: - shiftDisplayedDay

    @Test("shiftDisplayedDay increases offset by delta")
    func shiftForward() {
        let (vm, prayerService, _) = makeSUT()
        let now = Date()
        let times = makeTimes(base: now, future: true)
        prayerService.calculateResult = times
        prayerService.nextPrayerResult = (.dhuhr, now.addingTimeInterval(3600))

        vm.recalculate()
        vm.shiftDisplayedDay(by: 1)

        #expect(vm.effectiveDayOffset == 1)
    }

    @Test("shiftDisplayedDay clamps to max 30")
    func shiftClampMax() {
        let (vm, prayerService, _) = makeSUT()
        let now = Date()
        prayerService.calculateResult = makeTimes(base: now, future: true)
        prayerService.nextPrayerResult = (.dhuhr, now.addingTimeInterval(3600))

        vm.recalculate()
        // Shift far forward
        for _ in 0..<35 {
            vm.shiftDisplayedDay(by: 1)
        }

        #expect(vm.effectiveDayOffset == 30)
        #expect(vm.canShiftToNextDay == false)
    }

    @Test("shiftDisplayedDay clamps to min -7")
    func shiftClampMin() {
        let (vm, prayerService, _) = makeSUT()
        let now = Date()
        prayerService.calculateResult = makeTimes(base: now, future: true)
        prayerService.nextPrayerResult = (.dhuhr, now.addingTimeInterval(3600))

        vm.recalculate()
        for _ in 0..<10 {
            vm.shiftDisplayedDay(by: -1)
        }

        #expect(vm.effectiveDayOffset == -7)
        #expect(vm.canShiftToPreviousDay == false)
    }

    // MARK: - isNextPrayerRow

    @Test("isNextPrayerRow returns true for matching prayer")
    func isNextPrayerRowMatch() {
        let (vm, prayerService, _) = makeSUT()
        let now = Date()
        let dhuhrTime = now.addingTimeInterval(3600)
        prayerService.calculateResult = makeTimes(base: now, future: true)
        prayerService.nextPrayerResult = (.dhuhr, dhuhrTime)

        vm.recalculate()

        #expect(vm.isNextPrayerRow(prayer: .dhuhr, time: dhuhrTime) == true)
        #expect(vm.isNextPrayerRow(prayer: .asr, time: dhuhrTime) == false)
    }

    // MARK: - canShift

    @Test("canShiftToPreviousDay and canShiftToNextDay correct at boundaries")
    func canShiftBoundaries() {
        let (vm, prayerService, _) = makeSUT()
        let now = Date()
        prayerService.calculateResult = makeTimes(base: now, future: true)
        prayerService.nextPrayerResult = (.dhuhr, now.addingTimeInterval(3600))

        vm.recalculate()

        #expect(vm.canShiftToPreviousDay == true)
        #expect(vm.canShiftToNextDay == true)
    }

    // MARK: - Helpers

    private func makeSUT() -> (
        PrayerTimesCardView.ViewModel,
        MockPrayerTimeService,
        PrayerSettingsStore
    ) {
        let locationService = MockLocationService()
        locationService.currentLocation = CLLocation(latitude: 55.7558, longitude: 37.6173)

        let prayerService = MockPrayerTimeService()
        let settingsStore = PrayerSettingsStore()
        let vm = PrayerTimesCardView.ViewModel(
            locationService: locationService,
            prayerTimeService: prayerService,
            settingsStore: settingsStore
        )
        return (vm, prayerService, settingsStore)
    }

    private func makeTimes(base: Date, future: Bool) -> DailyPrayerTimes {
        let offset: TimeInterval = future ? 3600 : -3600
        return DailyPrayerTimes(
            date: base,
            fajr: base.addingTimeInterval(offset * 5),
            sunrise: base.addingTimeInterval(offset * 4),
            dhuhr: base.addingTimeInterval(offset * 3),
            asr: base.addingTimeInterval(offset * 2),
            maghrib: base.addingTimeInterval(offset * 1),
            isha: base.addingTimeInterval(offset * 0.5)
        )
    }
}
