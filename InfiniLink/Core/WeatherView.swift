//
//  WeatherView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/21/24.
//

import SwiftUI
import WeatherKit

struct WeatherView: View {
    @ObservedObject var weatherController = WeatherController.shared

    func sunEvent(for weather: Weather) -> (title: String, time: String)? {
        guard let today = weather.dailyForecast.first else { return nil }

        if let sunrise = today.sun.sunrise, Date() < sunrise {
            return ("Sunrise", sunrise.formatted(.dateTime.hour(.localized).minute()))
        } else if let sunset = today.sun.sunset, Date() < sunset {
            return ("Sunset", sunset.formatted(.dateTime.hour(.localized).minute()))
        } else if let sunrise = weather.dailyForecast.forecast.dropFirst().first?.sun.sunrise {
            return ("Sunrise", sunrise.formatted(.dateTime.hour(.localized).minute()))
        }

        return nil
    }

    var body: some View {
        GeometryReader { geo in
            VStack {
                if let weather = weatherController.weather {
                    List {
                        Section {
                            DetailHeaderView(
                                Header(title: String(format: "%.0f", weatherController.getTemperature(for: weather.currentWeather.temperature)) + weatherController.unit,
                                       subtitle: weather.currentWeather.condition.description,
                                       icon: weather.currentWeather.symbolName,
                                       accent: weatherController.getColor(for: weather.currentWeather.temperature)),
                                width: geo.size.width) {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                                        DetailHeaderSubItemView(title: "Min",
                                                                value: String(format: "%.0f", weatherController.getTemperature(for: weather.dailyForecast.first?.lowTemperature)) + weatherController.unit,
                                                                icon: ("sun.min.fill", weatherController.getColor(for: weather.dailyForecast.first?.lowTemperature)))
                                        DetailHeaderSubItemView(title: "Max",
                                                                value: String(format: "%.0f", weatherController.getTemperature(for: weather.dailyForecast.first?.highTemperature)) + weatherController.unit,
                                                                icon: ("sun.max.fill", weatherController.getColor(for: weather.dailyForecast.first?.highTemperature)))
                                        DetailHeaderSubItemView(title: "Feels Like",
                                                                value: String(format: "%.0f", weatherController.getTemperature(for: weather.currentWeather.apparentTemperature)) + weatherController.unit,
                                                                icon: ("thermometer.medium", weatherController.getColor(for: weather.currentWeather.apparentTemperature)))
                                        if let sunEvent = sunEvent(for: weather) {
                                            DetailHeaderSubItemView(title: sunEvent.title,
                                                                    value: sunEvent.time,
                                                                    icon: ("sun.and.horizon.fill", .yellow))
                                        }
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
                                            .foregroundStyle(weatherController.getColor(for: day.lowTemperature))
                                        Capsule()
                                            .frame(width: {
                                                let temperatureRange = day.highTemperature.value - day.lowTemperature.value
                                                let relativeWidth = CGFloat(temperatureRange) / 40.0 * 60
                                                return max(relativeWidth, 0)
                                            }(), height: 3)
                                        Text(String(format: "%.0f", weatherController.getTemperature(for: day.highTemperature)) + weatherController.unit)
                                            .foregroundStyle(weatherController.getColor(for: day.highTemperature))
                                    }
                                    .foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                } else {
                    Group {
                        if let error = weatherController.errorWhileFetching {
                            VStack(spacing: 4) {
                                Text("Error fetching weather")
                                    .font(.title3.weight(.semibold))
                                Text(error.localizedDescription)
                                    .foregroundStyle(.gray)
                            }
                            .multilineTextAlignment(.center)
                        } else {
                            ProgressView("Loading weather...")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .toolbar {
            NavigationLink {
                WeatherSettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
        .navigationTitle("Weather")
    }
}

#Preview {
    WeatherView()
}
