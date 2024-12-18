//
//  LocationManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/15/24.
//

import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    @AppStorage("useCurrentLocation") var useCurrentLocation = true
    @AppStorage("setLocation") var setLocation = "Cupertino"
    
    @Published var location: CLLocation?
    @Published var locationName: String = ""
    @Published var locationManager = CLLocationManager()
    
    func canGetUserLocation() -> Bool {
        return locationManager.authorizationStatus != .restricted && locationManager.authorizationStatus != .denied && locationManager.authorizationStatus != .notDetermined
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        
        self.requestLocation()
    }
    
    func getLocation() {
        if useCurrentLocation {
            self.requestLocation()
        } else {
            self.getCoordinateFrom(address: setLocation) { coordinate, error in
                if let coordinate = coordinate {
                    self.location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                } else if let error = error {
                    log("Error finding location for address \(self.setLocation): \(error.localizedDescription)", caller: "LocationManager")
                    print("Error finding location for address \(self.setLocation): \(error)")
                }
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
    
    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .restricted, .denied:
            log("Location access denied. Unable to get current location.", type: .info, caller: "LocationManager")
            print("Location access denied. Unable to get current location.")
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            WeatherController.shared.errorWhileFetching = error
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.requestLocation()
    }
}
