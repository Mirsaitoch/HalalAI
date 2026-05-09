//
//  HalalPlaceModelsTests.swift
//  HalalAITests
//

import Foundation
import CoreLocation
import MapKit
import Testing
@testable import HalalAI

struct HalalPlaceModelsTests {

    // MARK: - formattedDistance

    @Test("Distance under 1km shows meters")
    func distanceUnder1km() {
        let place = makePlace(latitude: 55.7558, longitude: 37.6173)
        let from = CLLocation(latitude: 55.7560, longitude: 37.6173) // ~22m away
        let formatted = place.formattedDistance(from: from)
        #expect(formatted.hasSuffix("м"), "Short distance should show meters: got '\(formatted)'")
    }

    @Test("Distance over 1km shows kilometers")
    func distanceOver1km() {
        let place = makePlace(latitude: 55.7558, longitude: 37.6173)
        let from = CLLocation(latitude: 55.7700, longitude: 37.6173) // ~1.5km away
        let formatted = place.formattedDistance(from: from)
        #expect(formatted.hasSuffix("км"), "Long distance should show km: got '\(formatted)'")
    }

    // MARK: - Equatable / Hashable

    @Test("HalalPlace equality is based on id")
    func equalityById() {
        let a = makePlace(id: "abc", latitude: 55.0, longitude: 37.0)
        let b = makePlace(id: "abc", latitude: 56.0, longitude: 38.0) // different coords, same id
        #expect(a == b)
    }

    @Test("HalalPlace with different ids are not equal")
    func inequalityByDifferentId() {
        let a = makePlace(id: "abc", latitude: 55.0, longitude: 37.0)
        let b = makePlace(id: "def", latitude: 55.0, longitude: 37.0) // same coords, different id
        #expect(a != b)
    }

    @Test("HalalPlace hashing uses id")
    func hashingById() {
        let a = makePlace(id: "test", latitude: 55.0, longitude: 37.0)
        let b = makePlace(id: "test", latitude: 56.0, longitude: 38.0)
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Helpers

    private func makePlace(
        id: String = UUID().uuidString,
        latitude: Double,
        longitude: Double
    ) -> HalalPlace {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        return HalalPlace(
            id: id,
            name: "Test",
            address: "Test Address",
            coordinate: coordinate,
            phoneNumber: nil,
            url: nil,
            mapItem: mapItem
        )
    }
}
