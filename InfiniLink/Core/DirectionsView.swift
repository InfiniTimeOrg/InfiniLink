//
//  DirectionsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/3/25.
//

import SwiftUI
import MapKit

struct DirectionsView: View {
    @StateObject private var directionsManager = DirectionsManager.shared
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var mapSearch = MapSearch()
    
    @FocusState private var isSearching: Bool
    // TODO: check
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        VStack {
            if locationManager.canGetUserLocation() {
                VStack {
                    if directionsManager.isLoading || mapSearch.isLoading {
                        ProgressView("Loading...")
                    } else {
                        List {
                            Section {
                                ForEach(mapSearch.locationResults, id: \.description) { location in
                                    Button {
                                        directionsManager.cancelRoute()
                                        locationManager.getCoordinateFrom(address: "\(location.title), \(location.subtitle)") { coordinate, error in
                                            if let coordinate {
                                                directionsManager.getDirections(to: coordinate)
                                                mapSearch.locationResults = []
                                            } else if let error {
                                                print("Error getting coordinate: \(error.localizedDescription)")
                                            }
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location.title)
                                                .foregroundStyle(Color.primary)
                                                .fontWeight(.semibold)
                                            if !location.subtitle.isEmpty {
                                                Text(location.subtitle)
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                    }
                                }
                            }
                            directions
                            mapView
                        }
                    }
                }
                .searchable(text: $mapSearch.searchTerm)
            } else {
                Text("To start a route, you need to enable \"Always Allow\" location permissions for InfiniLink in Settings.")
            }
        }
        .navigationTitle("Directions")
        .onChange(of: locationManager.location) { location in
            if let location {
                directionsManager.updateLocation(location)
                region.center = location.coordinate
            }
        }
    }
    
    var directions: some View {
        Group {
            if !directionsManager.steps.isEmpty {
                Section {
                    VStack {
                        let instructions = directionsManager.steps[directionsManager.currentStepIndex].instructions
                        if !instructions.isEmpty {
                            Text(instructions)
                                .font(.title2.weight(.bold))
                            Text("In \(directionsManager.distanceToNextStep) meters")
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            Section {
                ForEach(directionsManager.steps, id: \.instructions) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.instructions)
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                        Text(directionsManager.convertedDistance(step.distance))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    var mapView: some View {
        Section {
            Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .constant(.follow))
                .frame(height: 400)
        }
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    NavigationStack {
        DirectionsView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
