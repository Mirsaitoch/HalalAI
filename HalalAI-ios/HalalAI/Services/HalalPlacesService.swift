//
//  HalalPlacesService.swift
//  HalalAI
//

import Foundation
import MapKit

protocol HalalPlacesService {
    func searchNearby(coordinate: CLLocationCoordinate2D) async throws -> [HalalPlace]
}

final class HalalPlacesServiceImpl: HalalPlacesService {

    func searchNearby(coordinate: CLLocationCoordinate2D) async throws -> [HalalPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "халяль"
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        return response.mapItems.compactMap { item in
            guard let name = item.name else { return nil }
            let placemark = item.placemark
            let address = [
                placemark.thoroughfare,
                placemark.subThoroughfare,
                placemark.locality
            ]
                .compactMap { $0 }
                .joined(separator: ", ")

            return HalalPlace(
                id: UUID().uuidString,
                name: name,
                address: address.isEmpty ? "Адрес не указан" : address,
                coordinate: placemark.coordinate,
                phoneNumber: item.phoneNumber,
                url: item.url,
                mapItem: item
            )
        }
    }
}
