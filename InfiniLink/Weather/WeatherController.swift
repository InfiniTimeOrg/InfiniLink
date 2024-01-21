//
//  WeatherController.swift
//  InfiniLink
//
//  Created by Jen on 1/16/24.
//

import Foundation
import CoreLocation
import SwiftyJSON
import SwiftUI

class WeatherController: NSObject, ObservableObject, CLLocationManagerDelegate {
    @AppStorage("weatherData") var weatherData: Bool = false
    @AppStorage("userWeatherDisplay") var celsius: Bool = false
    @AppStorage("useCurrentLocation") var useCurrentLocation: Bool = false
    @AppStorage("setLocation") var setLocation : String = "Cupertino"
    
    static let shared = WeatherController()
    let bleWriteManager = BLEWriteManager()
    let bleManagerVal = BLEManagerVal.shared
    
    private let locationManager = CLLocationManager()
    
    var weatherapiFailed : Bool = false
    var nwsapiFailed : Bool = false
    let weatherapiKey : String = "" // API key for WeatherAPI goes here.
    let weatherapiBaseURL : String = "https://api.weatherapi.com/v1"
    
    enum WeatherAPI_Type {
        case wapi, nws
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
    }
    
    func tryRefreshingWeatherData() {
        if bleManagerVal.latitude == 0.0 && bleManagerVal.longitude == 0.0 {
            bleManagerVal.lastWeatherUpdateNWS = 0
            bleManagerVal.lastWeatherUpdateWAPI = 0
            updateWeatherData()
            return
        }
        
        var currentLocation: CLLocation!
        if locationManager.location != nil {
            let old_location = CLLocation(latitude: bleManagerVal.latitude, longitude: bleManagerVal.longitude)
            currentLocation = locationManager.location
            CLGeocoder().reverseGeocodeLocation(currentLocation) { [self] currentPlacemarks, error in
                
                guard let currentPlacemark = currentPlacemarks?.first else {
                    let errorString = error?.localizedDescription ?? "Unexpected Error"
                    print("Unable to reverse geocode the given location. Error: \(errorString)")
                    return
                }
                
                let currentGeoLocation = ReversedGeoLocation(with: currentPlacemark)
                
                CLGeocoder().reverseGeocodeLocation(old_location) { [self] oldPlacemarks, error in
                    
                    guard let oldPlacemark = oldPlacemarks?.first else {
                        let errorString = error?.localizedDescription ?? "Unexpected Error"
                        print("Unable to reverse geocode the given location. Error: \(errorString)")
                        return
                    }
                    
                    let oldGeoLocation = ReversedGeoLocation(with: oldPlacemark)
                    
                    if currentGeoLocation.city == oldGeoLocation.city {
                        bleManagerVal.lastWeatherUpdateNWS = 0
                        bleManagerVal.lastWeatherUpdateWAPI = 0
                        updateWeatherData()
                        return
                    }
                    
                }
                
            }
            bleManagerVal.latitude = currentLocation.coordinate.latitude
            bleManagerVal.longitude = currentLocation.coordinate.longitude
        }
        
        updateWeatherData()
    }
    
    func getCoordinateFrom(address: String, completion: @escaping(_ coordinate: CLLocationCoordinate2D?, _ error: Error?) -> () ) {
        CLGeocoder().geocodeAddressString(address) { completion($0?.first?.location?.coordinate, $1) }
    }
    
    private func retrieveWeatherData() {
        if !weatherData {return}
        callWeatherAPI()
    }
    
    private func retrieveWeatherDataThrough(API: WeatherAPI_Type) {
        var currentLocation: CLLocation!
        if useCurrentLocation {
            if locationManager.location != nil {
                currentLocation = locationManager.location
                bleManagerVal.latitude = currentLocation.coordinate.latitude
                bleManagerVal.longitude = currentLocation.coordinate.longitude
                bleWriteManager.sendNotification(title: "Wather Debug", body: "Updated Location\n\n\nlatitude: \(round(bleManagerVal.latitude))\nlongitude: \(round(bleManagerVal.longitude))")
            }
            if !(bleManagerVal.longitude == 0 && bleManagerVal.longitude == 0) {
                if API == WeatherAPI_Type.nws {
                    getForecastURL_NWS()
                } else {
                    getWeatherData_WAPI()
                }
            }
        } else {
            getCoordinateFrom(address: setLocation) { [self] coordinate, error in
                guard let coordinate = coordinate, error == nil else { return }
                bleManagerVal.latitude = coordinate.latitude
                bleManagerVal.longitude = coordinate.longitude
                if API == WeatherAPI_Type.nws {
                    getForecastURL_NWS()
                } else {
                    getWeatherData_WAPI()
                }
            }
        }
    }
    
    func startReceivingSignificantLocationChanges() {
        if !CLLocationManager.significantLocationChangeMonitoringAvailable() {
            print("Significant Location Change Monitoring is not Available")
            return
        }
        locationManager.delegate = self
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations
        locations: [CLLocation]) {
        let lastLocation = locations.last!
        
        bleWriteManager.sendNotification(title: "Wather Debug", body: "Significant Location Change Detective")
    }
    
    private func getWeatherData_WAPI() {
        let url = weatherapiBaseURL + "/forecast.json?key=" + weatherapiKey + "&q=" + String(bleManagerVal.latitude) + "," + String(bleManagerVal.longitude)
        URLSession.shared.dataTask(with: URL(string: url)!) { [self] (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                weatherapiFailed = true
                callWeatherAPI()
                return
            }
            guard let json = try? JSON(data: data!) else {
                print("Failed to access weather API")
                weatherapiFailed = true
                callWeatherAPI()
                return
            }
            
            DispatchQueue.main.async { [self] in
                bleManagerVal.weatherInformation.temperature = json["current"]["temp_c"].doubleValue
                bleManagerVal.weatherInformation.maxTemperature = json["forecast"]["forecastday"][0]["day"]["maxtemp_c"].doubleValue
                bleManagerVal.weatherInformation.minTemperature = json["forecast"]["forecastday"][0]["day"]["mintemp_c"].doubleValue
                
                sendWeatherData(temperature: bleManagerVal.weatherInformation.temperature, maxTemperature: bleManagerVal.weatherInformation.maxTemperature, minTemperature: bleManagerVal.weatherInformation.minTemperature, API: .wapi)
            }
            
        }.resume()
    }
    
    private func getForecastURL_NWS() {
        let url = "https://api.weather.gov/points/" + String(bleManagerVal.latitude) + "," + String(bleManagerVal.longitude)
        URLSession.shared.dataTask(with: URL(string: url)!) { [self] (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            if json["status"] == 404 {
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            
            let stationsURL = json["properties"]["observationStations"]
            let forecastURL = json["properties"]["forecastGridData"]
            self.getWeatherStation_NWS(stationsURL: stationsURL.stringValue, forecastURL: forecastURL.stringValue)
        }.resume()
    }
    
    private func getWeatherStation_NWS(stationsURL: String, forecastURL: String) {
        URLSession.shared.dataTask(with: URL(string: stationsURL)!) { [self] (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            let stationURL = json["observationStations"][0]
            self.getStationTemperature_NWS(forecastURL: forecastURL, stationURL: stationURL.stringValue)
        }.resume()
    }
    
    private func getStationTemperature_NWS(forecastURL: String, stationURL: String) {
        URLSession.shared.dataTask(with: URL(string: "\(stationURL)/observations")!) { [self] (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            
            var temperatureC = 0.0
            for idx in 1...json["features"].count{
                if json["features"][idx]["properties"]["temperature"]["qualityControl"].stringValue == "V" {
                    temperatureC = json["features"][idx]["properties"]["temperature"]["value"].doubleValue
                    break
                }
            }
            self.getWeatherForcast_NWS(forecastURL: forecastURL, temperatureC: temperatureC)
        }.resume()
    }
    
    private func getWeatherForcast_NWS(forecastURL: String, temperatureC: Double) {
        URLSession.shared.dataTask(with: URL(string: forecastURL)!) { [self] (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI()
                return
            }
            
            if json["status"] == 404 {
                bleWriteManager.sendNotification(title: "Wather Debug", body: "nwsapiFailed: error 404")
                return
            }
            
            DispatchQueue.main.async { [self] in
                bleManagerVal.weatherInformation.temperature = temperatureC
                bleManagerVal.weatherInformation.maxTemperature = json["properties"]["maxTemperature"]["values"][0]["value"].doubleValue
                bleManagerVal.weatherInformation.minTemperature = json["properties"]["minTemperature"]["values"][0]["value"].doubleValue
                
                if bleManagerVal.weatherInformation.maxTemperature == 0.0 && bleManagerVal.weatherInformation.minTemperature == 0.0 {
                    print(json)
                }
                
                sendWeatherData(temperature: bleManagerVal.weatherInformation.temperature, maxTemperature: bleManagerVal.weatherInformation.maxTemperature, minTemperature: bleManagerVal.weatherInformation.minTemperature, API: .nws)
            }
            
        }.resume()
    }
    
    private func sendWeatherData(temperature: Double, maxTemperature: Double, minTemperature: Double, API: WeatherAPI_Type) {
        let location = CLLocation(latitude: bleManagerVal.latitude, longitude: bleManagerVal.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [self] placemarks, error in

            guard let placemark = placemarks?.first else {
                let errorString = error?.localizedDescription ?? "Unexpected Error"
                print("Unable to reverse geocode the given location. Error: \(errorString)")
                return
            }

            
            let reversedGeoLocation = ReversedGeoLocation(with: placemark)
            setLocation = reversedGeoLocation.city
            //let cityName = reversedGeoLocation.city
            
            let api_name = API == .nws ? "NWS" : "WAPI"
            
            bleWriteManager.sendNotification(title: "\(api_name) Wather Debug", body: """
        Temperature \(round(temperature))
        Max Temp \(round(maxTemperature))
        Min Temp \(round(minTemperature))
        Lat \(round(bleManagerVal.latitude))
        Lon \(round(bleManagerVal.longitude))
        City \(setLocation)
        """)
            
            bleWriteManager.writeCurrentWeatherData(currentTemperature: temperature, minimumTemperature: minTemperature, maximumTemperature: maxTemperature, location: setLocation, icon: 2)
            //self.bleWriteManager.writeForecastWeatherData(minimumTemperature: [0, 0, 0], maximumTemperature: [32, 32, 32], icon: [randomIcon, randomIcon, randomIcon])
        }
    }
    
    private func callWeatherAPI() {
        //bleWriteManager.sendNotification(title: "Wather Debug", body: "nwsapiFailed: \(nwsapiFailed), : \(weatherapiFailed)")
        if nwsapiFailed == true && weatherapiFailed == true {
            bleWriteManager.sendNotification(title: "Wather Debug", body: "Error: Both Weather APIs are unavailable.")
            print("Error: Both APIs are unavailable.")
            nwsapiFailed = false
            weatherapiFailed = false
        } else if nwsapiFailed == false {
            let currentTime = Int(NSDate().timeIntervalSince1970 / 60 / 15) // Updates roughly every 15 minutes
            if bleManagerVal.lastWeatherUpdateNWS == currentTime {return}
            //DispatchQueue.main.async {
            self.bleManagerVal.lastWeatherUpdateNWS = currentTime
            //}
            // This function updates the weather info on the watch roughly every 15 minutes. Though it's only ever checks when the watch battey percentage changes or the watch registers new steps.
            print("Retrieving weather information using the NWS API")
            retrieveWeatherDataThrough(API: .nws)
        } else {
            let currentTime = Int(NSDate().timeIntervalSince1970 / 60 / 60)// Updates roughly every hour
            if bleManagerVal.lastWeatherUpdateWAPI == currentTime {return}
            //DispatchQueue.main.async {
            self.bleManagerVal.lastWeatherUpdateWAPI = currentTime
            //}
            // This function updates the weather info on the watch roughly every hour. Though it's only ever checks when the watch battey percentage changes or the watch registers new steps.
            print("Retrieving weather information using WeatherAPI")
            retrieveWeatherDataThrough(API: .wapi)
        }
    }
    
    func updateWeatherData() {
        if !useCurrentLocation {
            retrieveWeatherData()
            return
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            retrieveWeatherData()
            break
            
        case .restricted, .denied:
            disableLocationFeatures()
            break
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            bleManagerVal.lastWeatherUpdateNWS = 0
            bleManagerVal.lastWeatherUpdateWAPI = 0
            break
            
        default:
            break
        }
    }
    
    private func disableLocationFeatures() {
        useCurrentLocation = false
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
