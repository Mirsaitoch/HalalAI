//
//  HalalMapView.swift
//  HalalAI
//

import SwiftUI
import MapKit

struct HalalMapView: View {
    @Environment(Coordinator.self) var coordinator
    @Environment(LanguageStore.self) private var lang
    @State private var viewModel: ViewModel

    init(placesService: HalalPlacesService, locationService: LocationService) {
        _viewModel = State(initialValue: ViewModel(placesService: placesService, locationService: locationService))
    }

    var body: some View {
        ZStack {
            Map(position: Binding(
                get: { viewModel.cameraPosition },
                set: { viewModel.cameraPosition = $0 }
            )) {
                UserAnnotation()

                ForEach(viewModel.places) { place in
                    Marker(place.name, coordinate: place.coordinate)
                        .tint(.green)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            if viewModel.isLoading {
                ProgressView(lang.t("map.searching"))
                    .padding()
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            }

            if let errorMessage = viewModel.errorMessage, viewModel.places.isEmpty {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                        .padding()
                    Spacer()
                }
            }
        }
        .navigationTitle(lang.t("map.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(lang.t("common.back"), systemImage: "chevron.left") {
                    coordinator.dismiss()
                }
                .tint(.darkGreen)
            }
        }
        .sheet(item: Binding(
            get: { viewModel.selectedPlace },
            set: { viewModel.selectedPlace = $0 }
        )) { place in
            PlaceDetailSheet(place: place, viewModel: viewModel)
                .presentationDetents([.fraction(0.3)])
        }
        .task {
            await viewModel.loadPlaces()
        }
        .onMapCameraChange { context in
            // Allow camera to move freely after initial load
        }
    }
}

// MARK: - Place Detail Sheet

private struct PlaceDetailSheet: View {
    let place: HalalPlace
    let viewModel: HalalMapView.ViewModel
    @Environment(LanguageStore.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(place.name)
                .font(.title3)
                .bold()

            Label(place.address, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let distance = viewModel.distanceText(for: place) {
                Label(distance, systemImage: "location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let phone = place.phoneNumber {
                Label(phone, systemImage: "phone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(lang.t("map.directions"), systemImage: "arrow.triangle.turn.up.right.diamond") {
                viewModel.openInAppleMaps(place: place)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
