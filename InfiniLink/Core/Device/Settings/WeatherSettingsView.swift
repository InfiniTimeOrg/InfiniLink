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
                    ScrollView {
                        Section {
                            DetailHeaderView(
                                Header(title: String(format: "%.0f", weatherController.temperature) + weatherController.unit,
                                       subtitle: weather.currentWeather.condition.description,
                                       icon: weather.currentWeather.symbolName,
                                       accent: Color.yellow),
                                width: geo.size.width) {
                                    HStack {
                                        DetailHeaderSubItemView(title: "Min",
                                                                value: String(format: "%.0f", weather.currentWeather.temperature.value) + weatherController.unit)
                                        DetailHeaderSubItemView(title: "Max", value: String(format: "%.0f", weather.currentWeather.temperature.value) + weatherController.unit)
                                    }
                                }
                        }
                    }
                } else {
                    ProgressView("Loading weather...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Weather")
    }
}

#Preview {
    WeatherSettingsView()
}
