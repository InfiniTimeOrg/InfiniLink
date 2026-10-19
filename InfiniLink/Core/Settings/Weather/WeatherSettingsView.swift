//
//  WeatherSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct WeatherSettingsView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var weatherController = WeatherController.shared
    
    @AppStorage("useCurrentLocation") var useCurrentLocation = true
    @AppStorage("setLocation") var setLocation = "Cupertino"
    
    @StateObject private var editor = WatchSettingsEditor()
    
    var body: some View {
        List {
            Section(footer: Text("Use your current location to fetch local weather data. Location accuracy can be managed in Settings.")) {
                Toggle("Use Current Location", isOn: $useCurrentLocation)
            }
            if !useCurrentLocation {
                Section {
                    ForEach(locationManager.savedLocations, id: \.self) { location in
                        Button {
                            locationManager.selectLocation(location)
                        } label: {
                            HStack {
                                Text(location.name)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if location.address == setLocation {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        locationManager.removeLocations(at: offsets)
                    }
                    NavigationLink("Add Location") {
                        SetWeatherLocationView()
                    }
                } header: {
                    Text("Locations")
                } footer: {
                    Text("Choose which saved location your watch shows weather for.")
                }
            }
            if let file = editor.file, !editor.usingDefaults {
                Section {
                    Picker("Units on Watch", selection: Binding(
                        get: { file.weatherFormat },
                        set: { editor.file?.weatherFormat = $0 }
                    )) {
                        Text("Metric").tag(WeatherFormat.Metric.rawValue)
                        Text("Imperial").tag(WeatherFormat.Imperial.rawValue)
                    }
                    WatchSettingsSaveButton(editor: editor)
                }
            }
            if useCurrentLocation && locationManager.locationManager.authorizationStatus != .authorizedAlways {
                Section(footer: Text("Always allowed location access is required to fetch weather data while the app is not active.")) {
                    Button("Always Allow Access") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            if editor.file == nil {
                editor.load()
            }
        }
        .modifier(WatchSettingsAlerts(editor: editor, deviceName: DeviceManager.shared.name))
        .onChange(of: useCurrentLocation) { _ in
            locationManager.getLocation()
        }
    }
}

#Preview {
    WeatherSettingsView()
}
