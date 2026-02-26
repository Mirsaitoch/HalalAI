//
//  PrayerTimeService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 26.02.2026.
//

import Foundation
import CoreLocation
import Adhan

protocol PrayerTimeService: AnyObject {
    func calculateTimes(
        for date: Date,
        location: CLLocation,
        settings: PrayerSettings
    ) -> DailyPrayerTimes?

    func nextPrayer(from times: DailyPrayerTimes) -> (Prayer, Date)?
}

final class PrayerTimeServiceImpl: PrayerTimeService {

    func calculateTimes(
        for date: Date,
        location: CLLocation,
        settings: PrayerSettings
    ) -> DailyPrayerTimes? {
        let coords = Adhan.Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        let dc = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day], from: date)

        var params = settings.calculationMethod.adhanParams
        params.madhab = settings.madhab.adhanMadhab

        if let fajr = settings.customFajrAngle { params.fajrAngle = fajr }
        if let isha = settings.customIshaAngle { params.ishaAngle = isha }

        guard let times = Adhan.PrayerTimes(
            coordinates: coords,
            date: dc,
            calculationParameters: params
        ) else { return nil }

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        print("[PrayerTime] params: \(params)")

        print("[PrayerTime] Fajr=\(fmt.string(from: times.fajr)) Sunrise=\(fmt.string(from: times.sunrise)) Dhuhr=\(fmt.string(from: times.dhuhr)) Asr=\(fmt.string(from: times.asr)) Maghrib=\(fmt.string(from: times.maghrib)) Isha=\(fmt.string(from: times.isha))")

        return DailyPrayerTimes(
            date: date,
            fajr: times.fajr,
            sunrise: times.sunrise,
            dhuhr: times.dhuhr,
            asr: times.asr,
            maghrib: times.maghrib,
            isha: times.isha
        )
    }

    func nextPrayer(from times: DailyPrayerTimes) -> (Prayer, Date)? {
        let now = Date()
        return times.allPrayers.first { $0.1 > now }
    }
}

private extension PrayerCalculationMethod {
    var adhanParams: Adhan.CalculationParameters {
        switch self {
        case .muslimWorldLeague:
            return Adhan.CalculationMethod.muslimWorldLeague.params
        case .isna:
            return Adhan.CalculationMethod.northAmerica.params
        case .egypt:
            return Adhan.CalculationMethod.egyptian.params
        case .makkah:
            return Adhan.CalculationMethod.ummAlQura.params
        case .karachi:
            return Adhan.CalculationMethod.karachi.params
        case .tehran:
            return Adhan.CalculationMethod.tehran.params
        case .russia, .tatarstan:
            var params = Adhan.CalculationMethod.other.params
            params.fajrAngle = self.fajrAngle
            params.ishaAngle = self.ishaAngle
            return params
        }
    }
}

private extension Madhab {
    var adhanMadhab: Adhan.Madhab {
        switch self {
        case .shafi:  return .shafi
        case .hanafi: return .hanafi
        }
    }
}
