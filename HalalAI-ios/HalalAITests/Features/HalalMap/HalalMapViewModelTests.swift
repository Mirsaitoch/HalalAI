//
//  HalalMapViewModelTests.swift
//  HalalAITests
//

import Foundation
import CoreLocation
import MapKit
import Testing
@testable import HalalAI

@MainActor
struct HalalMapViewModelTests {

    @Test("Initial state has no places and no error")
    func initialState() {
        let (vm, _, _) = makeSUT()

        #expect(vm.places.isEmpty)
        #expect(vm.selectedPlace == nil)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadPlaces requests location")
    func loadPlacesRequestsLocation() async {
        let (vm, _, locationService) = makeSUT()
        locationService.currentLocation = CLLocation(latitude: 55.75, longitude: 37.62)

        await vm.loadPlaces()

        #expect(locationService.requestLocationCallCount >= 1)
    }

    @Test("loadPlaces sets error when location unavailable")
    func loadPlacesNoLocation() async {
        let (vm, _, locationService) = makeSUT()
        locationService.currentLocation = nil

        await vm.loadPlaces()

        #expect(vm.errorMessage == "Не удалось определить местоположение")
    }

    @Test("loadPlaces sets empty message when no places found")
    func loadPlacesEmpty() async {
        let (vm, placesService, locationService) = makeSUT()
        locationService.currentLocation = CLLocation(latitude: 55.75, longitude: 37.62)
        placesService.searchResult = .success([])

        await vm.loadPlaces()

        #expect(vm.places.isEmpty)
        #expect(vm.errorMessage == "Халяль заведения не найдены поблизости")
        #expect(vm.isLoading == false)
    }

    @Test("loadPlaces populates places on success")
    func loadPlacesSuccess() async {
        let (vm, placesService, locationService) = makeSUT()
        locationService.currentLocation = CLLocation(latitude: 55.75, longitude: 37.62)

        let place = HalalPlace(
            id: "1",
            name: "Test Cafe",
            address: "ул. Тестовая, 1",
            coordinate: CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62),
            phoneNumber: nil,
            url: nil,
            mapItem: MKMapItem()
        )
        placesService.searchResult = .success([place])

        await vm.loadPlaces()

        #expect(vm.places.count == 1)
        #expect(vm.places[0].name == "Test Cafe")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadPlaces sets error on service failure")
    func loadPlacesError() async {
        let (vm, placesService, locationService) = makeSUT()
        locationService.currentLocation = CLLocation(latitude: 55.75, longitude: 37.62)
        placesService.searchResult = .failure(NSError(domain: "test", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Network error"
        ]))

        await vm.loadPlaces()

        #expect(vm.errorMessage?.contains("Ошибка поиска") == true)
        #expect(vm.isLoading == false)
    }

    @Test("distanceText returns nil without location")
    func distanceTextNoLocation() {
        let (vm, _, locationService) = makeSUT()
        locationService.currentLocation = nil

        let place = HalalPlace(
            id: "1", name: "Test", address: "Addr",
            coordinate: CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62),
            phoneNumber: nil, url: nil, mapItem: MKMapItem()
        )

        #expect(vm.distanceText(for: place) == nil)
    }

    @Test("distanceText returns formatted distance with location")
    func distanceTextWithLocation() {
        let (vm, _, locationService) = makeSUT()
        locationService.currentLocation = CLLocation(latitude: 55.75, longitude: 37.62)

        let place = HalalPlace(
            id: "1", name: "Test", address: "Addr",
            coordinate: CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62),
            phoneNumber: nil, url: nil, mapItem: MKMapItem()
        )

        let text = vm.distanceText(for: place)
        #expect(text != nil)
    }

    // MARK: - Helpers

    private func makeSUT() -> (HalalMapView.ViewModel, MockHalalPlacesService, MockLocationService) {
        let placesService = MockHalalPlacesService()
        let locationService = MockLocationService()
        let vm = HalalMapView.ViewModel(placesService: placesService, locationService: locationService)
        return (vm, placesService, locationService)
    }
}
