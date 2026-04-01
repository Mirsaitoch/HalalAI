//
//  HalalMapView.swift
//  HalalAI
//

import SwiftUI
import MapKit

struct HalalMapView: View {
    @Environment(Coordinator.self) var coordinator
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
                ProgressView("Поиск халяль мест...")
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
        .navigationTitle("Халяль места")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Назад", systemImage: "chevron.left") {
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

            Button("Построить маршрут", systemImage: "arrow.triangle.turn.up.right.diamond") {
                viewModel.openInAppleMaps(place: place)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
