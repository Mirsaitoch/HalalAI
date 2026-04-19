//
//  HalalPlaceModels.swift
//  HalalAI
//

import Foundation
import CoreLocation
import MapKit

struct HalalPlace: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let phoneNumber: String?
    let url: URL?
    let mapItem: MKMapItem

    static func == (lhs: HalalPlace, rhs: HalalPlace) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Distance from a given location, formatted as a readable string.
    func formattedDistance(from location: CLLocation) -> String {
        let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = location.distance(from: placeLocation)
        if distance < 1000 {
            return distance.formatted(.number.precision(.fractionLength(0))) + " м"
        } else {
            return (distance / 1000).formatted(.number.precision(.fractionLength(1))) + " км"
        }
    }
}
