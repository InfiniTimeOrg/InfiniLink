//
//  LocationManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/15/24.
//

import Foundation
import CoreLocation
import SwiftUI

struct SavedLocation: Codable, Hashable {
    let name: String
    let address: String
}

enum AddressComponent: CaseIterable {
    case name
    case locality
    case administrativeArea
    case country
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    @AppStorage("useCurrentLocation") var useCurrentLocation = true
    @AppStorage("setLocation") var setLocation = "Cupertino"
    @AppStorage("displayLocation") var displayLocation = "Cupertino"
    
    @Published var savedLocations: [SavedLocation] = [] {
        didSet {
            guard let data = try? JSONEncoder().encode(savedLocations) else { return }
            UserDefaults.standard.set(data, forKey: "savedWeatherLocations")
        }
    }
    
    @Published var location: CLLocation?
    @Published var locationName: String = ""
    let locationManager = CLLocationManager()
    
    private var deviceLocationRequests: [(CLLocation?) -> Void] = []
    
    func canGetUserLocation() -> Bool {
        return locationManager.authorizationStatus != .restricted && locationManager.authorizationStatus != .denied && locationManager.authorizationStatus != .notDetermined
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        
        if let data = UserDefaults.standard.data(forKey: "savedWeatherLocations"),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = decoded
        } else if UserDefaults.standard.string(forKey: "setLocation") != nil {
            // Migrate the location from before saved locations existed
            savedLocations = [SavedLocation(name: displayLocation, address: setLocation)]
        }
        
        self.requestLocation()
    }
    
    func selectLocation(_ location: SavedLocation) {
        displayLocation = location.name
        setLocation(location.address)
    }
    
    func addLocation(_ location: SavedLocation) {
        if !savedLocations.contains(location) {
            savedLocations.append(location)
        }
        selectLocation(location)
    }
    
    func removeLocations(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        
        if !savedLocations.contains(where: { $0.address == setLocation }) {
            if let first = savedLocations.first {
                selectLocation(first)
            } else {
                useCurrentLocation = true
                getLocation()
            }
        }
    }
    
    // Setting the location triggers a weather fetch
    func getLocation() {
        if useCurrentLocation {
            self.requestLocation()
        } else {
            self.getCoordinateFrom(address: setLocation) { coordinate, error in
                if let coordinate = coordinate {
                    self.locationName = self.displayLocation
                    self.location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                } else if let error = error {
                    log("Error finding location for address \(self.setLocation): \(error.localizedDescription)", caller: "LocationManager")
                }
            }
        }
    }
    
    private func updateLocationName(for location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error {
                log("Error reverse geocoding location name: \(error.localizedDescription)", caller: "LocationManager")
            }
            guard let name = placemarks?.first?.locality ?? placemarks?.first?.name ?? placemarks?.first?.administrativeArea else { return }
            
            DispatchQueue.main.async {
                self?.locationName = name
            }
        }
    }
    
    func setLocation(_ location: String) {
        self.setLocation = location
        self.getLocation()
    }
    
    func getCoordinateFrom(address: String, completion: @escaping (_ coordinate: CLLocationCoordinate2D?, _ error: Error?) -> ()) {
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            completion(placemarks?.first?.location?.coordinate, error)
        }
    }
    
    func getAddressFrom(coordinate: CLLocationCoordinate2D, addressComponents: [AddressComponent] = AddressComponent.allCases, completion: @escaping (_ address: String?) -> ()) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var components: [String] = []
                
                if let name = placemark.name, addressComponents.contains(.name) {
                    components.append(name)
                }
                if let locality = placemark.locality, addressComponents.contains(.locality) {
                    components.append(locality)
                }
                if let administrativeArea = placemark.administrativeArea, addressComponents.contains(.administrativeArea) {
                    components.append(administrativeArea)
                }
                if let country = placemark.country, addressComponents.contains(.country) {
                    components.append(country)
                }
                
                completion(components.joined(separator: ", "))
            } else {
                if let error = error {
                    log("Error during reverse geocoding: \(error.localizedDescription)", caller: "LocationManager")
                }
                completion(nil)
            }
        }
    }
    
    // The phone's own location, even when weather uses a saved city
    func requestDeviceLocation(completion: @escaping (CLLocation?) -> Void) {
        guard canGetUserLocation() else {
            completion(nil)
            return
        }
        
        deviceLocationRequests.append(completion)
        locationManager.requestLocation()
    }
    
    private func finishDeviceLocationRequests(with location: CLLocation?) {
        deviceLocationRequests.forEach { $0(location) }
        deviceLocationRequests = []
    }
    
    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .restricted, .denied:
            log("Location access denied. Unable to get current location.", type: .info, caller: "LocationManager")
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finishDeviceLocationRequests(with: locations.last)
        
        if let location = locations.last, useCurrentLocation {
            self.location = location
            updateLocationName(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finishDeviceLocationRequests(with: manager.location)
        
        if useCurrentLocation {
            DispatchQueue.main.async {
                WeatherController.shared.errorWhileFetching = error
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.requestLocation()
    }
}
