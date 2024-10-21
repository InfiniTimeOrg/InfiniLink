//
//  WeatherSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct WeatherSettingsView: View {
    @ObservedObject var weatherController = WeatherController.shared
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                if let weather = weatherController.weather {
                    List {
                        Section {
                            DetailHeaderView(
                                Header(title: String(format: "%.0f", weatherController.temperature) + weatherController.unit,
                                       subtitle: weather.currentWeather.condition.description,
                                       icon: weather.currentWeather.symbolName,
                                       accent: Color.yellow),
                                width: geo.size.width) {
                                    HStack {
                                        DetailHeaderSubItemView(title: "Min",
                                                                value: String(format: "%.0f", weatherController.getTemperature(for: weather.dailyForecast.first?.lowTemperature)) + weatherController.unit)
                                        DetailHeaderSubItemView(title: "Max", value: String(format: "%.0f", weatherController.getTemperature(for: weather.dailyForecast.first?.highTemperature)) + weatherController.unit)
                                    }
                                }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        Section {
                            ForEach(weather.dailyForecast.forecast.dropFirst().prefix(5), id: \.date) { day in
                                HStack(spacing: 7) {
                                    Image(systemName: day.symbolName)
                                        .font(.body.weight(.medium))
                                    Text({
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "EEE"
                                        let dayInWeek = dateFormatter.string(from: day.date)
                                        
                                        return dayInWeek
                                    }())
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Text(String(format: "%.0f", weatherController.getTemperature(for: day.lowTemperature)) + weatherController.unit)
                                            .foregroundStyle(.gray)
                                        Rectangle()
                                            .frame(width: {
                                                let temperatureRange = day.highTemperature.value - day.lowTemperature.value
                                                let relativeWidth = CGFloat(temperatureRange) / 40.0 * 60
                                                return relativeWidth
                                            }(), height: 3)
                                            .cornerRadius(30)
                                            .background(Material.thin)
                                        Text(String(format: "%.0f", weatherController.getTemperature(for: day.highTemperature)) + weatherController.unit)
                                            .foregroundStyle(Color.gray)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView("Loading weather...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Weather")
    }
}

#Preview {
    WeatherSettingsView()
}
