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
                                                                value: String(format: "%.0f", weatherController.getTemperature(celsius: weather.dailyForecast.first?.lowTemperature)) + weatherController.unit)
                                        DetailHeaderSubItemView(title: "Max", value: String(format: "%.0f", weatherController.getTemperature(celsius: weather.dailyForecast.first?.highTemperature)) + weatherController.unit)
                                    }
                                }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        Section {
                            ForEach(weather.dailyForecast.forecast, id: \.date) { day in
                                HStack {
                                    Image(systemName: day.symbolName)
                                    Text({
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "EEE"
                                        let dayInWeek = dateFormatter.string(from: day.date)
                                        
                                        return dayInWeek
                                    }())
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
