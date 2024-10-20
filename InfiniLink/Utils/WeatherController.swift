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

@MainActor
class WeatherController: ObservableObject {
    static let shared = WeatherController()
    
    @Published var weather: Weather?
    
    @AppStorage("latitude") var latitude: Double = 0.0
    @AppStorage("longitude") var longitude: Double = 0.0
    
    @Published var temperature = 0.0
    @Published var forecastDays = [DayWeather]()
    @Published var unit = ""
    
    private let service = WeatherService()
    private var locationManager = LocationManager()
    private var bleWriteManager = BLEWriteManager()
    
    var unitTemperature: UnitTemperature {
        switch DeviceManager.shared.settings.weatherFormat {
        case .Metric:
            return .celsius
        case .Imperial:
            return .fahrenheit
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
                
                switch unitTemperature {
                case .celsius:
                    self.unit = "°C"
                case .fahrenheit:
                    self.unit = "°F"
                default:
                    self.unit = "°C"
                }
                
                self.temperature = weather.currentWeather.temperature.converted(to: unitTemperature).value
                self.forecastDays = Array(weather.dailyForecast.prefix(5))
                
                self.writeForecastToDevice()
            } catch {
                print("Failed to fetch weather: \(error)")
            }
        }
    }
    
    func writeForecastToDevice() {
        if let weather = weather {
            guard let firstDay = weather.dailyForecast.first else { return }
            
            self.bleWriteManager.writeCurrentWeatherData(currentTemperature: weather.currentWeather.temperature.value, minimumTemperature: firstDay.lowTemperature.value, maximumTemperature: firstDay.highTemperature.value, location: locationManager.locationName, icon: getIcon())
            self.bleWriteManager.writeForecastWeatherData(minimumTemperature: forecastDays.compactMap({ $0.lowTemperature.value }), maximumTemperature: forecastDays.compactMap({ $0.highTemperature.value }), icon: forecastDays.compactMap({ UInt8($0.symbolName.id) }))
        }
    }
    
    func getTemperature(celsius: Measurement<UnitTemperature>?) -> Double {
        return celsius?.converted(to: unitTemperature).value ?? 0
    }
    
    func getIcon() -> UInt8 {
        return 1
    }
    
    private var cancellables = Set<AnyCancellable>()
}
