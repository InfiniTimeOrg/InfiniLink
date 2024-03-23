//
//  WeatherDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/4/24.
//

import SwiftUI

struct WeatherDetailView: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    
    var celsius: Bool {
        (UnitTemperature.current == .celsius && deviceData.chosenWeatherMode == "System") || deviceData.chosenWeatherMode == "Metric"
    }
    
    func getIcon(icon: Int) -> String {
        switch icon {
        case 0:
            return "sun.max.fill"
        case 1:
            return "cloud.sun.fill"
        case 2, 3:
            return "cloud.fill"
        case 4, 5:
            return "cloud.rain.fill"
        case 6:
            return "cloud.bolt.rain.fill"
        case 7:
            return "cloud.snow.fill"
        case 8:
            return "cloud.fog.fill"
        default:
            return "slash.circle"
        }
    }
    func temp(_ temp: Double) -> String {
        if self.celsius {
            return String(Int(round(temp))) + "°" + "C"
        } else {
            return String(Int(round(temp * 1.8 + 32))) + "°" + "F"
        }
    }
    
    let deviceData: DeviceData = DeviceData()
    var dateFormatter = DateFormatter()
    
    @State var forecastDates: [String] = []
    
    init() {
        dateFormatter.dateFormat = "E"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("weather", comment: ""))
                    .font(.title.bold())
                Spacer()
                SheetCloseButton()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
            Divider()
            VStack {
                if bleManagerVal.loadingWeather {
                    Spacer()
                    ProgressView(NSLocalizedString("loading_weather", comment: ""))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            Image(systemName: getIcon(icon: bleManagerVal.weatherInformation.icon))
                                .font(.system(size: 45).weight(.medium))
                            HStack {
                                Text(temp(bleManagerVal.weatherInformation.minTemperature))
                                    .foregroundColor(.gray)
                                Text(temp(bleManagerVal.weatherInformation.temperature))
                                    .font(.system(size: 35).weight(.semibold))
                                Text(temp(bleManagerVal.weatherInformation.maxTemperature))
                                    .foregroundColor(.gray)
                            }
                            Text(bleManagerVal.weatherInformation.shortDescription)
                                .foregroundColor(.gray)
                                .font(.body.weight(.semibold))
                        }
                        .padding()
                        VStack(spacing: 10) {
                            ForEach(bleManagerVal.weatherForecastDays, id: \.name) { day in
                                HStack(spacing: 6) {
                                    Text(day.name)
                                        .font(.body.weight(.medium))
                                    Image(systemName: getIcon(icon: Int(day.icon)))
                                        .imageScale(.large)
                                        .font(.body.weight(.medium))
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Text(temp(day.maxTemperature))
                                            .foregroundColor(.lightGray)
                                        Rectangle()
                                            .frame(height: 3)
                                            .frame(width: {
                                                let temperatureRange = day.maxTemperature - day.minTemperature
                                                let relativeWidth = CGFloat(temperatureRange) / 40.0 * 60
                                                return relativeWidth
                                            }())
                                            .cornerRadius(30)
                                            .background(Material.thin)
                                        Text(temp(day.minTemperature))
                                            .foregroundColor(.lightGray)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(15)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

#Preview {
    WeatherDetailView()
        .onAppear {
            BLEManagerVal.shared.weatherInformation.shortDescription = "Light Rain"
            BLEManagerVal.shared.weatherInformation.icon = 4
            BLEManagerVal.shared.weatherInformation.temperature = 4
            BLEManagerVal.shared.weatherInformation.maxTemperature = 3
            BLEManagerVal.shared.weatherInformation.maxTemperature = 5
            BLEManagerVal.shared.weatherForecastDays.append(WeatherForecastDay(maxTemperature: 3, minTemperature: 2, icon: 2, name: "Sat"))
            BLEManagerVal.shared.weatherForecastDays.append(WeatherForecastDay(maxTemperature: 1.6, minTemperature: 1.3, icon: 6, name: "Sun"))
            BLEManagerVal.shared.weatherForecastDays.append(WeatherForecastDay(maxTemperature: 2.6, minTemperature: 1.9, icon: 3, name: "Mon"))
        }
}
