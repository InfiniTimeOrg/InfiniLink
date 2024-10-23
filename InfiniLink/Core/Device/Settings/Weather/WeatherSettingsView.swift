//
//  WeatherSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct WeatherSettingsView: View {
    @ObservedObject var locationManager = LocationManager.shared
    
    @AppStorage("useCurrentLocation") var useCurrentLocation = true
    @AppStorage("displayLocation") var displayLocation = "Cupertino"
    
    var body: some View {
        List {
            Section(footer: Text("Use your current location to fetch local weather data. Location accuracy can be managed in Settings.")) {
                Toggle("Use Current Location", isOn: $useCurrentLocation)
            }
            Section(footer: Text("Set a fixed location to use to fetch weather.")) {
                NavigationLink {
                    SetWeatherLocationView()
                } label: {
                    HStack {
                        Text("Custom Location")
                        Spacer()
                        Text(displayLocation)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .disabled(useCurrentLocation)
            if useCurrentLocation && locationManager.locationManager.authorizationStatus != .authorizedAlways {
                Section(footer: Text("Always allowed location access is required to fetch weather data while the app is not active.")) {
                    Button("Always Allow Access") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle("Settings")
        .onChange(of: useCurrentLocation) { _ in
            locationManager.getLocation()
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }
}

#Preview {
    WeatherSettingsView()
}
