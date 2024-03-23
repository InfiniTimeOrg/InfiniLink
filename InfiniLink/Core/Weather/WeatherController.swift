//
//  WeatherController.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/4/24.
//

import Foundation
import CoreLocation
import SwiftyJSON
import SwiftUI

class WeatherController: NSObject, ObservableObject, CLLocationManagerDelegate {
    @AppStorage("weatherData") var weatherData: Bool = false
    @AppStorage("useCurrentLocation") var useCurrentLocation: Bool = false
    @AppStorage("setLocation") var setLocation : String = "Cupertino"
    @AppStorage("lastLocation") var lastLocation : String = "Cupertino"
    @AppStorage("displayLocation") var displayLocation : String = "Cupertino"
    @AppStorage("debugMode") var debugMode: Bool = false
    
    static let shared = WeatherController()
    let bleWriteManager = BLEWriteManager()
    let bleManagerVal = BLEManagerVal.shared
    
    private let locationManager = CLLocationManager()
    
    let weatherapiKey: String = "cc80d76d17a740ebb8a160008241801"
    let weatherapiBaseURL: String = "https://api.weatherapi.com/v1"
    var weatherapiFailed: Bool = false
    var nwsapiFailed: Bool = false
    
    enum WeatherAPI_Type {
        case wapi, nws
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
    }
    
    func tryRefreshingWeatherData() {
        if bleManagerVal.latitude == 0.0 && bleManagerVal.longitude == 0.0 {
            updateWeatherData(ignoreTimeLimits: true)
            return
        }
        
        var currentLocation: CLLocation!
        if locationManager.location != nil {
            let old_location = CLLocation(latitude: bleManagerVal.latitude, longitude: bleManagerVal.longitude)
            if useCurrentLocation {
                currentLocation = locationManager.location
                tryComparingLocations(oldLocation: old_location, newLocation: currentLocation)
            } else {
                getCoordinateFrom(address: setLocation) { [self] coordinate, error in
                    guard let coordinate = coordinate, error == nil else {
                        print("Error!")
                        DebugLogManager.shared.debug(error: "There was an error retrieving coordinates from user-set location", log: .app, date: Date())
                        return
                    }
                    
                    currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    tryComparingLocations(oldLocation: old_location, newLocation: currentLocation)
                }
            }
        }
        
        updateWeatherData(ignoreTimeLimits: false)
    }
    
    func getCoordinateFrom(address: String, completion: @escaping(_ coordinate: CLLocationCoordinate2D?, _ error: Error?) -> () ) {
        CLGeocoder().geocodeAddressString(address) { completion($0?.first?.location?.coordinate, $1) }
    }
    
    private func tryComparingLocations(oldLocation: CLLocation, newLocation: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(newLocation) { [self] currentPlacemarks, error in
            
            guard let currentPlacemark = currentPlacemarks?.first else {
                let errorString = error?.localizedDescription ?? "Unexpected Error"
                print("Unable to reverse geocode the given location with error: \(errorString)")
                DebugLogManager.shared.debug(error: "Unable to reverse geocode the given location with error: \(errorString)", log: .app, date: Date())
                return
            }
            
            let currentGeoLocation = ReversedGeoLocation(with: currentPlacemark)
            
            CLGeocoder().reverseGeocodeLocation(oldLocation) { [self] oldPlacemarks, error in
                
                guard let oldPlacemark = oldPlacemarks?.first else {
                    let errorString = error?.localizedDescription ?? "Unexpected Error"
                    print("Unable to reverse geocode the given location with error: \(errorString)")
                    DebugLogManager.shared.debug(error: "Unable to reverse geocode the given location with error: \(errorString)", log: .app, date: Date())
                    return
                }
                
                let oldGeoLocation = ReversedGeoLocation(with: oldPlacemark)
                
                if currentGeoLocation.city != oldGeoLocation.city || currentGeoLocation.state != oldGeoLocation.state || currentGeoLocation.country != oldGeoLocation.country {
                    updateWeatherData(ignoreTimeLimits: true)
                    return
                }
                
            }
            
        }
    }
    
    private func retrieveWeatherDataThrough(API: WeatherAPI_Type) {
        var currentLocation: CLLocation!
        if useCurrentLocation {
            startReceivingSignificantLocationChanges()
            if locationManager.location != nil {
                currentLocation = locationManager.location
                bleManagerVal.latitude = currentLocation.coordinate.latitude
                bleManagerVal.longitude = currentLocation.coordinate.longitude
                
                DebugLogManager.shared.debug(error: "Updated Location; latitude: \(round(bleManagerVal.latitude)), longitude: \(round(bleManagerVal.longitude))", log: .app, date: Date())
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
                guard let coordinate = coordinate, error == nil else {
                    print("There was an error retrieving coordinates from user-set location")
                    DebugLogManager.shared.debug(error: "There was an error retrieving coordinates from user-set location", log: .app, date: Date())
                    return
                }
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
            DebugLogManager.shared.debug(error: "Significant Location Change Monitoring is not Available", log: .app, date: Date())
            return
        }
        locationManager.delegate = self
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let lastLocation = locations.last!
        if !useCurrentLocation {return}
        tryRefreshingWeatherData()
    }
    
    private func getWeatherData_WAPI() {
        let url = weatherapiBaseURL + "/forecast.json?key=" + weatherapiKey + "&q=" + String(bleManagerVal.latitude) + "," + String(bleManagerVal.longitude) + "&days=5"
        
        print(url)
        URLSession.shared.dataTask(with: URL(string: url)!) { [self] (data, _, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                weatherapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            guard let json = try? JSON(data: data!) else {
                print("Failed to access weather API")
                DebugLogManager.shared.debug(error: "Failed to access WeatherAPI", log: .app, date: Date())
                weatherapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            
            DispatchQueue.main.async { [self] in
                bleManagerVal.weatherInformation.temperature = json["current"]["temp_c"].doubleValue
                bleManagerVal.weatherInformation.maxTemperature = json["forecast"]["forecastday"][0]["day"]["maxtemp_c"].doubleValue
                bleManagerVal.weatherInformation.minTemperature = json["forecast"]["forecastday"][0]["day"]["mintemp_c"].doubleValue
                
                if debugMode {
                    let debugDescription = "WeatherAPI short description: \(json["forecast"]["forecastday"][0]["day"]["condition"]["text"])"
                    print(debugDescription)
                    DebugLogManager.shared.debug(error: debugDescription, log: .app, date: Date())
                }
                
                bleManagerVal.weatherInformation.icon = Int(getIcon_WAPI(description: json["forecast"]["forecastday"][0]["day"]["condition"]["text"].stringValue))
                bleManagerVal.weatherInformation.forecastIcon = []
                bleManagerVal.weatherInformation.forecastMaxTemperature = []
                bleManagerVal.weatherInformation.forecastMinTemperature = []
                bleManagerVal.weatherInformation.shortDescription = json["forecast"]["forecastday"][0]["day"]["condition"]["text"].stringValue
                
                if json["forecast"]["forecastday"][0].count > 1 {
                    let calendar = Calendar.current
                    let currentDate = Date()
                    
                    for idx in 1...json["forecast"]["forecastday"][0].count {
                        bleManagerVal.weatherInformation.forecastIcon = []
                        bleManagerVal.weatherInformation.forecastMaxTemperature = []
                        bleManagerVal.weatherInformation.forecastMinTemperature = []
                        bleManagerVal.weatherForecastDays = []
                        
                        bleManagerVal.weatherInformation.forecastIcon.append(getIcon_WAPI(description: json["forecast"]["forecastday"][idx]["day"]["condition"]["text"].stringValue))
                        bleManagerVal.weatherInformation.forecastMaxTemperature.append(json["forecast"]["forecastday"][idx]["day"]["maxtemp_c"].doubleValue)
                        bleManagerVal.weatherInformation.forecastMinTemperature.append(json["forecast"]["forecastday"][idx]["day"]["mintemp_c"].doubleValue)
                        
                        if let futureDate = calendar.date(byAdding: .day, value: idx, to: currentDate) {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "EEE"
                            let dayName = dateFormatter.string(from: futureDate)
                            
                            bleManagerVal.weatherForecastDays.append(WeatherForecastDay(maxTemperature: json["forecast"]["forecastday"][idx]["day"]["maxtemp_c"].doubleValue, minTemperature: json["forecast"]["forecastday"][idx]["day"]["mintemp_c"].doubleValue, icon: getIcon_WAPI(description: json["forecast"]["forecastday"][idx]["day"]["condition"]["text"].stringValue), name: dayName))
                        }
                        
                        if idx >= 5 {
                            break
                        }
                    }
                }
                
                sendWeatherData(temperature: bleManagerVal.weatherInformation.temperature, maxTemperature: bleManagerVal.weatherInformation.maxTemperature, minTemperature: bleManagerVal.weatherInformation.minTemperature, icon: bleManagerVal.weatherInformation.icon, forecastMaxTemperature: bleManagerVal.weatherInformation.forecastMaxTemperature, forecastMinTemperature: bleManagerVal.weatherInformation.forecastMinTemperature, forecastIcon: bleManagerVal.weatherInformation.forecastIcon, API: .wapi)
            }
            
        }.resume()
    }
    
    private func getIcon_WAPI(description: String) -> UInt8 {
        switch description {
        case "Sunny", "Clear":
            return 0
        case "Partly cloudly":
            return 1
        case "Cloudly", "Overcast", "Patchy rain possible", "Patchy sleet possible", "Patchy freezing drizzle possible", "Thundery outbreaks possible":
            return 2
        case "Patchy light drizzle", "Heavy freezing drizzle", "Drizzle", "Light rain", "Moderate rain", "Moderate rain at times", "Heavy rain at times", "Heavy rain", "Light freezing rain", "Moderate or heavy freezing rain", "Ice pellets", "Light rain shower", "Moderate or heavy rain shower", "Torrential rain shower", "Light sleet showers", "Moderate or heavy sleet showers", "Light showers of ice pellets", "Moderate or heavy showers of ice pellets":
            return 4
        case "Patchy light rain with thunder", "Moderate or heavy rain with thunder":
            return 6
        case "Blowing snow", "Blizzard", "Patchy light snow", "Light snow", "Patchy moderate snow", "Moderate snow", "Patchy heavy snow", "Heavy snow", "Light snow showers", "Moderate or heavy snow showers", "Patchy light snow with thunder", "Moderate or heavy snow with thunder":
            return 7
        case "Fog", "Freezing fog", "Mist":
            return 8
        default:
            return 0
        }
    }
    
    private func getForecastURL_NWS() {
        let url = "https://api.weather.gov/points/" + String(bleManagerVal.latitude) + "," + String(bleManagerVal.longitude)
        print("url: \(url)")
        URLSession.shared.dataTask(with: URL(string: url)!) { [self] (data, _, err) in
            if err != nil {
                print("Error retrieving forecast URL with the NWS API with error: \(err!.localizedDescription)")
                DebugLogManager.shared.debug(error: "Error retrieving forecast URL with the NWS API with error: \(err!.localizedDescription)", log: .app, date: Date())
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            if json["status"] == 404 {
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
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
                print("Error retrieving weather stations with the NWS API with error: \(err!.localizedDescription)")
                DebugLogManager.shared.debug(error: "Error retrieving weather stations with the NWS API with error: \(err!.localizedDescription)", log: .app, date: Date())
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            let stationURL = json["observationStations"][0]
            self.getStationTemperature_NWS(forecastURL: forecastURL, stationURL: stationURL.stringValue)
        }.resume()
    }
    
    private func getStationTemperature_NWS(forecastURL: String, stationURL: String) {
        URLSession.shared.dataTask(with: URL(string: "\(stationURL)/observations")!) { [self] (data, _, err) in
            if err != nil {
                print("There was an error retrieving data from the NWS API: \(err!.localizedDescription)")
                DebugLogManager.shared.debug(error: "There was an error retrieving data from the NWS API: \(err!.localizedDescription)", log: .app, date: Date())
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            if json["status"] == 404 || json["status"] == 500 {
                print("Failed to get weather data from NWS API with error code: \(json["status"])")
                DebugLogManager.shared.debug(error: "Failed to get weather data from NWS API with error code: \(json["status"])", log: .app, date: Date())
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            
            var temperatureC = 0.0
            
            for idx in 1...json["features"].count {
                if json["features"][idx]["properties"]["temperature"]["qualityControl"].stringValue == "V" {
                    temperatureC = json["features"][idx]["properties"]["temperature"]["value"].doubleValue
                    
                    if debugMode {
                        let debugDescription = "NWS API short description: \(json["features"][idx]["properties"]["textDescription"])"
                        print(debugDescription)
                        DebugLogManager.shared.debug(error: debugDescription, log: .app, date: Date())
                    }
                    
                    bleManagerVal.weatherInformation.icon = Int(getIcon_NWS(description: json["features"][idx]["properties"]["textDescription"].stringValue))
                    bleManagerVal.weatherInformation.shortDescription = json["features"][idx]["properties"]["textDescription"].stringValue
                    break
                }
            }
            
            self.getWeatherForcast_NWS(forecastURL: forecastURL, temperatureC: temperatureC, icon: bleManagerVal.weatherInformation.icon)
        }.resume()
    }
    
    // The textDescription docs are out of date so these cases might be slightly different than the fetched data and may need to be updated
    private func getIcon_NWS(description: String) -> UInt8 {
        switch description {
        case "Fair", "Clear", "Fair with Haze", "Clear with Haze", "Fair and Breezy", "Clear and Breezy", "Windy", "Breezy", "Fair and Windy", "Mostly Clear":
            return 0
        case "A Few Clouds", "A Few Clouds with Haze", "A Few Clouds and Breezy", "A Few Clouds and Windy", "Partly Cloudy", "Partly Cloudy with Haze", "Partly Cloudy and Breezy", "Partly Cloudy and Windy":
            return 1
        case "Cloudy", "Mostly Cloudy", "Mostly Cloudy with Haze", "Mostly Cloudy and Breezy", "Mostly Cloudy and Wind", "Cloudy and Windy":
            return 2
        case "Overcast", "Overcast with Haze", "Overcast and Breezy", "Overcast and Windy", "Hurricane Watch", "Funnel Cloud", "Funnel Cloud in Vicinity", "Tornado/Water Spout", "Tornado":
            return 3
        case "Showers in Vicinity Snow", "Snow Showers in Vicinity", "Snow Showers in Vicinity Fog/Mist", "Snow Showers in Vicinity Fog":
            return 4
        case "Light Rain", "Drizzle", "Light Drizzle", "Heavy Drizzle", "Light Rain and Fog/Mist", "Drizzle and Fog/Mist", "Light Drizzle and Fog/Mist", "Heavy Drizzle and Fog/Mist", "Light Rain and Fog", "Drizzle and Fog", "Light Drizzle and Fog", "Heavy Drizzle Fog", "Rain", "Heavy and Rain", "Rain and Fog/Mist", "Heavy Rain and Fog/Mist", "Rain and Fog", "Heavy Rain and Fog":
            return 5
        case "Thunderstorm in Vicinity", "Thunderstorm in Vicinity Haze", "Hurricane Warning", "Tropical Storm Watch", "Tropical Storm Warning", "Tropical Storm Conditions presently exist w/Hurricane Warning in effect":
            return 6
        case "Snow", "Light Snow", "Light Snow and Fog/Mist", "Heavy Snow", "Snow Showers", "Heavy Snow Showers", "Showers Snow", "Light Showers Snow", "Heavy Showers Snow", "Snow Fog/Mist", "Light Snow Fog/Mist", "Heavy Snow Fog/Mist", "Snow Showers Fog/Mist", "Light Snow Showers", "Heavy Snow Showers Fog/Mist", "Showers Snow Fog/Mist", "Light Showers Snow Fog/Mist", "Heavy Showers Snow Fog/Mist", "Snow Fog", "Light Snow Fog", "Heavy Snow Fog", "Snow Showers Fog", "Light Snow Showers Fog", "Heavy Snow Showers Fog", "Low Drifting Snow", "Blowing Snow", "Snow Low Drifting Snow", "Snow Blowing Snow", "Light Snow Low Drifting Snow", "Light Snow Blowing Snow", "Light Snow Blowing Snow Fog/Mist", "Heavy Snow Low Drifting Snow", "Heavy Snow Blowing Snow", "Thunderstorm Snow", "Light Thunderstorm Snow", "Heavy Thunderstorm Snow", "Snow Grains", "Grains", "Heavy Snow Grains", "Heavy Blowing Snow", "Blowing Snow in Vicinity", "Blizzard":
            return 7
        case "Dust", "Low Drifting Dust", "Blowing Dust", "Sand", "Blowing Sand", "Low Drifting Sand", "Dust/Sand Whirls", "Dust/Sand Whirls in Vicinity", "Dust Storm", "Heavy Dust Storm", "Dust Storm in Vicinity", "Sand Storm", "Heavy Sand Storm", "Sand Storm in Vicinity", "Smoke", "Haze", "Fog/Mist", "Freezing Fog", "Shallow Fog", "Partial Fog", "Patches of Fog", "Fog in Vicinity", "Freezing Fog in Vicinity", "Shallow Fog in Vicinity", "Partial Fog in Vicinity", "Patches of Fog in Vicinity", "Showers in Vicinity Fog", "Light Freezing Fog", "Heavy Freezing Fog", "Fog":
            return 8
        default:
            return 0
        }
    }
    
    private func getWeatherForcast_NWS(forecastURL: String, temperatureC: Double, icon: Int) {
        URLSession.shared.dataTask(with: URL(string: forecastURL)!) { [self] (data, _, err) in
            if err != nil {
                print("Failed to get weather forecast from NWS API with error: \(err!.localizedDescription)")
                DebugLogManager.shared.debug(error: "Failed to get weather forecast from NWS API with error: \(err!.localizedDescription)", log: .app, date: Date())
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            
            if json["status"] == 404 || json["status"] == 500 {
                print("Failed to get weather data from NWS API with error code: \(json["status"])")
                DebugLogManager.shared.debug(error: "Failed to get weather data from NWS API with error code: \(json["status"])", log: .app, date: Date())
                DispatchQueue.main.async {
                    self.bleManagerVal.lastWeatherUpdateNWS = 0
                }
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            
            DispatchQueue.main.async { [self] in
                bleManagerVal.weatherInformation.temperature = temperatureC
                bleManagerVal.weatherInformation.maxTemperature = json["properties"]["maxTemperature"]["values"][0]["value"].doubleValue
                bleManagerVal.weatherInformation.minTemperature = json["properties"]["minTemperature"]["values"][0]["value"].doubleValue
                
                bleManagerVal.weatherInformation.forecastIcon = []
                bleManagerVal.weatherInformation.forecastMaxTemperature = []
                bleManagerVal.weatherInformation.forecastMinTemperature = []
                bleManagerVal.weatherForecastDays = []
                
                let currentDate = Date()
                let calendar = Calendar.current
                
                for idx in 1...json["properties"]["maxTemperature"]["values"].count {
                    let maxTemp = json["properties"]["maxTemperature"]["values"][idx]["value"].doubleValue
                    let minTemp = json["properties"]["minTemperature"]["values"][idx]["value"].doubleValue
                    
                    bleManagerVal.weatherInformation.forecastMaxTemperature.append(maxTemp)
                    bleManagerVal.weatherInformation.forecastMinTemperature.append(minTemp)
                    
                    if let futureDate = calendar.date(byAdding: .day, value: idx, to: currentDate) {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "EEE"
                        let dayName = dateFormatter.string(from: futureDate)
                        
                        bleManagerVal.weatherForecastDays.append(WeatherForecastDay(maxTemperature: maxTemp, minTemperature: minTemp, icon: getIcon_NWS(description: ""), name: dayName))
                    }
                    
                    if idx >= 5 {
                        break
                    }
                }
                
                if bleManagerVal.weatherInformation.maxTemperature == 0.0 && bleManagerVal.weatherInformation.minTemperature == 0.0 {
                    print(json)
                }
                
                getWeatherForcastIcons_WAPI(forecastURL: forecastURL)
            }
            
        }.resume()
    }
    
    private func getWeatherForcastIcons_WAPI(forecastURL: String) {
        URLSession.shared.dataTask(with: URL(string: "\(forecastURL)/forecast")!) { [self] (data, _, err) in
            if err != nil {
                print("Failed to get weather forecast from NWS API with error: \(err!.localizedDescription)")
                DebugLogManager.shared.debug(error: "Failed to get weather forecast from NWS API with error: \(err!.localizedDescription)", log: .app, date: Date())
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            guard let json = try? JSON(data: data!) else {
                nwsapiFailed = true
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            
            if json["status"] == 404 || json["status"] == 500 {
                print("Failed to get weather data from NWS API with error code: \(json["status"])")
                DebugLogManager.shared.debug(error: "Failed to get weather data from NWS API with error code: \(json["status"])", log: .app, date: Date())
                DispatchQueue.main.async {
                    self.bleManagerVal.lastWeatherUpdateNWS = 0
                }
                callWeatherAPI(canUpdateNWS: true, canUpdateWAPI: true)
                return
            }
            
            DispatchQueue.main.async { [self] in
                bleManagerVal.weatherInformation.forecastIcon = []
                for idx in 1...json["properties"]["periods"].count {
                    if json["properties"]["periods"][idx]["isDaytime"].boolValue {
                        bleManagerVal.weatherInformation.forecastIcon.append(getIcon_NWS(description: json["properties"]["periods"][idx]["shortForecast"].stringValue))
                    }
                    if bleManagerVal.weatherInformation.forecastIcon.count >= 5 {break}
                }
                
                sendWeatherData(temperature: bleManagerVal.weatherInformation.temperature, maxTemperature: bleManagerVal.weatherInformation.maxTemperature, minTemperature: bleManagerVal.weatherInformation.minTemperature, icon: bleManagerVal.weatherInformation.icon, forecastMaxTemperature: bleManagerVal.weatherInformation.forecastMaxTemperature, forecastMinTemperature: bleManagerVal.weatherInformation.forecastMinTemperature, forecastIcon: bleManagerVal.weatherInformation.forecastIcon, API: .nws)
            }
        }.resume()
    }
    
    private func sendWeatherData(temperature: Double, maxTemperature: Double, minTemperature: Double, icon: Int, forecastMaxTemperature: [Double], forecastMinTemperature: [Double], forecastIcon: [UInt8], API: WeatherAPI_Type) {
        let location = CLLocation(latitude: bleManagerVal.latitude, longitude: bleManagerVal.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [self] placemarks, error in
            
            guard let placemark = placemarks?.first else {
                let errorString = error?.localizedDescription ?? "Unexpected Error"
                print("Unable to reverse geocode the given location. Error: \(errorString)")
                DebugLogManager.shared.debug(error: "Unable to reverse geocode the given location with error: \(errorString)", log: .app, date: Date())
                return
            }
            
            
            let reversedGeoLocation = ReversedGeoLocation(with: placemark)
            lastLocation = reversedGeoLocation.city + ", " + reversedGeoLocation.state + ", " + reversedGeoLocation.country
            if useCurrentLocation {setLocation = reversedGeoLocation.city + ", " + reversedGeoLocation.state + ", " + reversedGeoLocation.country}
            displayLocation = reversedGeoLocation.city
            
            bleWriteManager.writeCurrentWeatherData(currentTemperature: temperature, minimumTemperature: minTemperature, maximumTemperature: maxTemperature, location: reversedGeoLocation.city, icon: UInt8(icon))
            bleWriteManager.writeForecastWeatherData(minimumTemperature: forecastMinTemperature, maximumTemperature: forecastMaxTemperature, icon: forecastIcon)
            
            nwsapiFailed = false
            weatherapiFailed = false
            bleManagerVal.loadingWeather = false
        }
    }
    
    private func callWeatherAPI(canUpdateNWS: Bool, canUpdateWAPI: Bool) {
        if nwsapiFailed == true && weatherapiFailed == true {
            print("Failed to get weather data from NWS API and WeatherAPI")
            DebugLogManager.shared.debug(error: "Error: failed to get weather data from NWS API and WeatherAPI", log: .app, date: Date())
            nwsapiFailed = false
            weatherapiFailed = false
        } else if nwsapiFailed == false {
            if !canUpdateNWS {return}
            // This function updates the weather info on the watch roughly every 15 minutes. Though it's only ever checks when the watch battey percentage changes or the watch registers new steps.
            print("Retrieving weather information using the NWS API")
            DebugLogManager.shared.debug(error: "Retrieving weather information using the NWS API", log: .app, date: Date())
            retrieveWeatherDataThrough(API: .nws)
        } else {
            if !canUpdateWAPI {return}
            // This function updates the weather info on the watch roughly every hour. Though it's only ever checks when the watch battey percentage changes or the watch registers new steps.
            print("Retrieving weather information using WeatherAPI")
            DebugLogManager.shared.debug(error: "Retrieving weather information using WeatherAPI", log: .app, date: Date())
            retrieveWeatherDataThrough(API: .wapi)
        }
    }
    
    func updateWeatherData(ignoreTimeLimits: Bool) {
        if !weatherData {return}
        
        var canUpdateNWS = true
        var canUpdateWAPI = true
        
        if !ignoreTimeLimits {
            let currentTimeNWS = Int(NSDate().timeIntervalSince1970 / 60 / 15) // Updates roughly every 15 minutes
            let currentTimeWAPI = Int(NSDate().timeIntervalSince1970 / 60 / 60)// Updates roughly every hour
            if bleManagerVal.lastWeatherUpdateNWS == currentTimeNWS {canUpdateNWS = false}
            if bleManagerVal.lastWeatherUpdateWAPI == currentTimeWAPI {canUpdateWAPI = false}
            bleManagerVal.lastWeatherUpdateNWS = currentTimeNWS
            bleManagerVal.lastWeatherUpdateWAPI = currentTimeWAPI
        }
        
        if !useCurrentLocation {
            callWeatherAPI(canUpdateNWS: canUpdateNWS, canUpdateWAPI: canUpdateWAPI)
            return
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            callWeatherAPI(canUpdateNWS: canUpdateNWS, canUpdateWAPI: canUpdateWAPI)
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
        print("Location features are disabled")
        DebugLogManager.shared.debug(error: "Location features are disabled", log: .app, date: Date())
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

protocol LocalizableDimension: Dimension {
    associatedtype T: Dimension
    static var allUnits: [T] { get }
}

extension LocalizableDimension {
    static var current: T {
        let baseUnit = allUnits[0]
        let formatter = MeasurementFormatter()
        formatter.locale = .current
        let measurement = Measurement(value: 0, unit: baseUnit)
        let string = formatter.string(from: measurement)
        for unit in allUnits {
            if string.contains(unit.symbol) {
                return unit
            }
        }
        return baseUnit
    }
}

extension UnitTemperature: LocalizableDimension {
    static let allUnits: [UnitTemperature] = [.celsius, .fahrenheit, .kelvin]
}

extension UnitSpeed: LocalizableDimension {
    static let allUnits: [UnitSpeed] = [.kilometersPerHour, .milesPerHour, .metersPerSecond, .knots]
}
