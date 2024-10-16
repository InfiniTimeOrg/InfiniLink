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

enum TemperatureUnit: String {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
    case kelvin = "Kelvin"
}

@MainActor
class WeatherController: ObservableObject {
    static let shared = WeatherController()
    
    @Published var weather: Weather?
    
    @AppStorage("latitude") var latitude: Double = 0.0
    @AppStorage("longitude") var longitude: Double = 0.0
    @AppStorage("temperatureUnit") var temperatureUnit: TemperatureUnit = .celsius
    
    @Published var temperature = 0.0
    @Published var unit = ""
    
    private let service = WeatherService()
    private var locationManager = LocationManager()
    
    var unitTemperature: UnitTemperature {
        switch temperatureUnit {
        case .celsius:
            return .celsius
        case .fahrenheit:
            return .fahrenheit
        case .kelvin:
            return .kelvin
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
                self?.fetchWeatherData()
            }
            .store(in: &cancellables)
    }
    
    func fetchWeatherData() {
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        Task {
            do {
                let weather = try await service.weather(for: currentLocation)
                self.weather = weather
                
                switch weather.currentWeather.temperature.unit {
                case .celsius:
                    self.unit = "°C"
                case .fahrenheit:
                    self.unit = "°F"
                case .kelvin:
                    self.unit = "°K"
                default:
                    self.unit = "°C"
                }
                
                self.temperature = weather.currentWeather.temperature.converted(to: unitTemperature).value
            } catch {
                print("Failed to fetch weather: \(error)")
            }
        }
    }
    
    func refreshWeather() {
        fetchWeatherData()
    }
    
    private var cancellables = Set<AnyCancellable>()
}
