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
    
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Published var weather: Weather?
    
    @Published var errorWhileFetching: Error?
    
    @AppStorage("latitude") var latitude: Double = 0.0
    @AppStorage("longitude") var longitude: Double = 0.0
    
    @AppStorage("setLocation") var setLocation = "Cupertino"
    
    @AppStorage("useCurrentLocation") var useCurrentLocation = true
    
    @Published var temperature = 0.0
    @Published var forecastDays = [DayWeather]()
    
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
                
                self?.fetchWeatherData()
            }
            .store(in: &cancellables)
    }
    
    func fetchWeatherData() {
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        weather = nil
        
        Task {
            do {
                let weather = try await service.weather(for: currentLocation)
                
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
            guard let firstDay = weather.dailyForecast.first else { return }
            
            self.bleWriteManager.writeCurrentWeatherData(currentTemperature: weather.currentWeather.temperature.value, minimumTemperature: firstDay.lowTemperature.value, maximumTemperature: firstDay.highTemperature.value, location: locationManager.locationName, icon: getIcon(from: firstDay.symbolName))
            self.bleWriteManager.writeForecastWeatherData(minimumTemperature: forecastDays.compactMap({ $0.lowTemperature.value }), maximumTemperature: forecastDays.compactMap({ $0.highTemperature.value }), icon: forecastDays.compactMap({ getIcon(from: $0.symbolName) }))
        }
    }
    
    func getTemperature(for value: Measurement<UnitTemperature>?) -> Double {
        return value?.converted(to: unitTemperature).value ?? 0
    }
    
    func getIcon(from icon: String) -> UInt8 {
        switch icon {
        // TODO: add cases
        default:
            return 0
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
}
