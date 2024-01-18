//
//  WeatherController.swift
//  InfiniLink
//
//  Created by Jen on 1/16/24.
//

import Foundation
import CoreLocation
import SwiftyJSON

class WeatherController: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherController()
    let bleWriteManager = BLEWriteManager()
    let bleManagerVal = BLEManagerVal.shared
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
    }
    
    // This function check if the weather data should be updated. It calls the data to be updated on the watch roughly every 15 minutes. Though it's only ever checks when the watch battey percentage changes or the watch registers new steps.
    func weatherDataUpdateCheck() {
        let currentTime = Int(NSDate().timeIntervalSince1970 / 60 / 15)
        if bleManagerVal.lastWeatherUpdate == currentTime {
            return
        }
        weatherDataUpdate()
        bleManagerVal.lastWeatherUpdate = currentTime
        print("Weather Data Updated")
    }
    
    private func retrieveWeatherData() {
        var currentLocation: CLLocation!
        if locationManager.location != nil {
            currentLocation = locationManager.location
            bleManagerVal.latitude = currentLocation.coordinate.latitude
            bleManagerVal.longitude = currentLocation.coordinate.longitude
        }
        getForecastURL()
    }
    
    private func getForecastURL() {
        let url = "https://api.weather.gov/points/" + String(bleManagerVal.latitude) + "," + String(bleManagerVal.longitude)
        print("url \(url)")
        URLSession.shared.dataTask(with: URL(string: url)!) { (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                return
            }
            let json = try! JSON(data: data!)
            let forecastHourlyURL = json["properties"]["forecastHourly"]
            let forecastURL = json["properties"]["forecastGridData"]
            self.getWeatheForecastHourly(forecastHourlyURL: forecastHourlyURL.stringValue, forecastURL: forecastURL.stringValue)
        }.resume()
    }
    
    private func getWeatheForecastHourly(forecastHourlyURL: String, forecastURL: String) {
        URLSession.shared.dataTask(with: URL(string: forecastHourlyURL)!) { (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                return
            }
            let json = try! JSON(data: data!)
            let temperature = json["properties"]["periods"][0]["temperature"]
            self.getWeatherForcast(forecastURL: forecastURL, temperatureF: temperature.doubleValue)
        }.resume()
    }
    
    private func getWeatherForcast(forecastURL: String, temperatureF: Double) {
        URLSession.shared.dataTask(with: URL(string: forecastURL)!) { [self] (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                return
            }
            let json = try! JSON(data: data!)
            let temperature = Int(round((temperatureF - 32.0) * (5.0 / 9.0)))
            let maxTemperature = Int(round(json["properties"]["maxTemperature"]["values"][0]["value"].doubleValue))
            let minTemperature = Int(round(json["properties"]["minTemperature"]["values"][0]["value"].doubleValue))
            
            let location = CLLocation(latitude: bleManagerVal.latitude, longitude: bleManagerVal.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in

                guard let placemark = placemarks?.first else {
                    let errorString = error?.localizedDescription ?? "Unexpected Error"
                    print("Unable to reverse geocode the given location. Error: \(errorString)")
                    return
                }

                
                let reversedGeoLocation = ReversedGeoLocation(with: placemark)
                let cityName = reversedGeoLocation.city
                
                print("temperature \(temperature)")
                print("maxTemperature \(maxTemperature)")
                print("minTemperature \(minTemperature)")
                print("cityName \(cityName)")
                
                self.bleWriteManager.writeCurrentWeatherData(currentTemperature: temperature, minimumTemperature: minTemperature, maximumTemperature: maxTemperature, location: cityName, icon: 2)
                //self.bleWriteManager.writeForecastWeatherData(minimumTemperature: [0, 0, 0], maximumTemperature: [32, 32, 32], icon: [randomIcon, randomIcon, randomIcon])
            }
        }.resume()
    }
    
    private func weatherDataUpdate() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            retrieveWeatherData()
            break
            
        case .restricted, .denied:
            disableLocationFeatures()
            break
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            bleManagerVal.lastWeatherUpdate = 0
            break
            
        default:
            break
        }
    }
    
    private func disableLocationFeatures() {
        print("Disable Location Features")
    }
    
    struct ReversedGeoLocation {
        let name: String            // eg. Apple Inc.
        let streetName: String      // eg. Infinite Loop
        let streetNumber: String    // eg. 1
        let city: String            // eg. Cupertino
        let state: String           // eg. CA
        let zipCode: String         // eg. 95014
        let country: String         // eg. United States
        let isoCountryCode: String  // eg. US
        
        var formattedAddress: String {
            return """
            \(name),
            \(streetNumber) \(streetName),
            \(city), \(state) \(zipCode)
            \(country)
            """
        }
        
        // Handle optionals as needed
        init(with placemark: CLPlacemark) {
            self.name           = placemark.name ?? ""
            self.streetName     = placemark.thoroughfare ?? ""
            self.streetNumber   = placemark.subThoroughfare ?? ""
            self.city           = placemark.locality ?? ""
            self.state          = placemark.administrativeArea ?? ""
            self.zipCode        = placemark.postalCode ?? ""
            self.country        = placemark.country ?? ""
            self.isoCountryCode = placemark.isoCountryCode ?? ""
        }
    }
    
}
