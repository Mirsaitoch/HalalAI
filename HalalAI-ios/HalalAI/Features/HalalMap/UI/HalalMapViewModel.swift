//
//  HalalMapViewModel.swift
//  HalalAI
//

import Foundation
import MapKit
import SwiftUI

extension HalalMapView {
    @MainActor
    @Observable
    final class ViewModel {
        var places: [HalalPlace] = []
        var selectedPlace: HalalPlace?
        var isLoading = false
        var errorMessage: String?
        var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

        private let placesService: HalalPlacesService
        private let locationService: LocationService

        init(placesService: HalalPlacesService, locationService: LocationService) {
            self.placesService = placesService
            self.locationService = locationService
        }

        func loadPlaces() async {
            guard !isLoading else { return }

            locationService.requestLocation()

            // Wait briefly for location if not yet available
            if locationService.currentLocation == nil {
                try? await Task.sleep(for: .seconds(1))
            }

            guard let location = locationService.currentLocation else {
                errorMessage = "Не удалось определить местоположение"
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                places = try await placesService.searchNearby(coordinate: location.coordinate)
                if places.isEmpty {
                    errorMessage = "Халяль заведения не найдены поблизости"
                }
            } catch {
                errorMessage = "Ошибка поиска: \(error.localizedDescription)"
            }

            isLoading = false
        }

        func openInAppleMaps(place: HalalPlace) {
            place.mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }

        func distanceText(for place: HalalPlace) -> String? {
            guard let location = locationService.currentLocation else { return nil }
            return place.formattedDistance(from: location)
        }
    }
}
