//
//  WeatherController.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/15/24.
//

import SwiftUI
import WeatherKit
import CoreLocation
import Combine

class WeatherController: ObservableObject {
    static let shared = WeatherController()
    
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @AppStorage("latitude") var latitude: Double = 0.0
    @AppStorage("longitude") var longitude: Double = 0.0
    
    @AppStorage("setLocation") var setLocation = "Cupertino"
    
    @AppStorage("useCurrentLocation") var useCurrentLocation = true
    
    @Published var weather: Weather?
    @Published var errorWhileFetching: Error?
    @Published var temperature = 0.0
    @Published var forecastDays = [DayWeather]()
    @Published var lastTimeWeatherFetched: Date?
    
    private let service = WeatherService()
    private var locationManager = LocationManager.shared
    private var bleWriteManager = BLEWriteManager()
    
    var unitTemperature: UnitTemperature {
        switch deviceManager.settings.weatherFormat {
        case .Metric:
            return .celsius
        case .Imperial:
            return .fahrenheit
        }
    }
    var unit: String {
        switch unitTemperature {
        case .celsius:
            return "°C"
        case .fahrenheit:
            return "°F"
        default:
            return "°C"
        }
    }
    
    init() {
        setupLocationObserver()
    }
    
    private func setupLocationObserver() {
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.latitude = location.coordinate.latitude
                self?.longitude = location.coordinate.longitude
                
                // Bypass the check function, this one will already ensure we're not calling multiple times a minute
                self?.fetchWeatherData()
            }
            .store(in: &cancellables)
    }
    
    func checkForUpdate() {
        // This function is called every five seconds
        // We want to update the weather no more than once every two minutes, and no less than once every 15 minutes
        
        let guardInterval: TimeInterval = 900 // 15 mins
        
        if abs(lastTimeWeatherFetched?.timeIntervalSinceNow ?? 0) >= guardInterval {
            // The weather hasn't been fetched (location hasn't been updated) in the past 15 minutes, so fetch it now
            fetchWeatherData(checkTimeInterval: false)
        }
    }
    
    func fetchWeatherData(checkTimeInterval: Bool = true) {
        let guardInterval: TimeInterval = 120 // 2 mins
        
        // Make sure the weather has not been fetched in the past 2 minutes
        guard !checkTimeInterval || abs(lastTimeWeatherFetched?.timeIntervalSinceNow ?? guardInterval) >= guardInterval else { return }
        
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        Task {
            do {
                let weather = try await service.weather(for: currentLocation)
                
                self.lastTimeWeatherFetched = Date()
                self.weather = weather
                self.forecastDays = Array(weather.dailyForecast.dropFirst().prefix(5))
                
                self.writeForecastToDevice()
            } catch {
                self.errorWhileFetching = error
            }
        }
    }
    
    func writeForecastToDevice() {
        if let weather = weather {
            guard let first = weather.dailyForecast.first else { return }
            
            self.bleWriteManager.writeCurrentWeatherData(currentTemperature: weather.currentWeather.temperature.value, minimumTemperature: first.lowTemperature.value, maximumTemperature: first.highTemperature.value, location: locationManager.locationName, icon: getIcon(from: weather.currentWeather.symbolName))
            self.bleWriteManager.writeForecastWeatherData(minimumTemperature: forecastDays.compactMap({ $0.lowTemperature.value }), maximumTemperature: forecastDays.compactMap({ $0.highTemperature.value }), icon: forecastDays.compactMap({ getIcon(from: $0.symbolName) }))
        }
    }
    
    func getTemperature(for value: Measurement<UnitTemperature>?) -> Double {
        return value?.converted(to: unitTemperature).value ?? 0
    }
    
    func getIcon(from icon: String) -> UInt8 {
        // WeatherKit icons don't contain .fill, but we're keeping this here as a safeguard just in case that changes
        let icon = icon.replacingOccurrences(of: ".fill", with: "")
        
        /*
        - 0 = Sun, clear sky
        - 1 = Few clouds
        - 2 = Clouds
        - 3 = Heavy clouds
        - 4 = Clouds & rain
        - 5 = Rain
        - 6 = Thunderstorm
        - 7 = Snow
        - 8 = Mist, smog
        */
        switch icon {
            // Don't include the "sunny" icons, because they'll be handled by default
        case "cloud.sun":
            return 1
        case "cloud":
            return 2
        case "cloud.drizzle", "cloud.sun.rain", "cloud.moon.rain":
            return 4
        case "cloud.rain", "cloud.heavyrain":
            return 5
        case "cloud.bolt", "cloud.bolt.rain", "cloud.moon.bolt":
            return 6
        case "cloud.hail", "cloud.snow", "cloud.sleet", "snowflake":
            return 7
        case "cloud.fog", "moon.haze", "sun.haze":
            return 8
        default:
            return 0
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
}
