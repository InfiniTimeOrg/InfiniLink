//
//  WeatherDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/4/24.
//

import SwiftUI

struct WeatherDetailView: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    
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
    
    var celsius: Bool {
        (UnitTemperature.current == .celsius && deviceData.chosenWeatherMode == "System") || deviceData.chosenWeatherMode == "Metric"
    }
    
    let deviceData: DeviceData = DeviceData()
    var dateFormatter = DateFormatter()
    
    @State var forecastDates: [String] = []
    
    init() {
        dateFormatter.dateFormat = "E"
    }
    
    var body: some View {
        VStack {
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
                    VStack(spacing: 8) {
                        Image(systemName: getIcon(icon: bleManagerVal.weatherInformation.icon))
                            .font(.system(size: 45).weight(.medium))
                        HStack {
                            Group {
                                if celsius {
                                    Text(String(Int(round(bleManagerVal.weatherInformation.minTemperature))) + "°" + "C")
                                } else {
                                    Text(String(Int(round(bleManagerVal.weatherInformation.minTemperature * 1.8 + 32))) + "°" + "F")
                                }
                            }
                            .foregroundColor(.gray)
                            Group {
                                if celsius {
                                    Text(String(Int(round(bleManagerVal.weatherInformation.temperature))) + "°" + "C")
                                } else {
                                    Text(String(Int(round(bleManagerVal.weatherInformation.temperature * 1.8 + 32))) + "°" + "F")
                                }
                            }
                            .font(.system(size: 35).weight(.semibold))
                            Group {
                                if celsius {
                                    Text(String(Int(round(bleManagerVal.weatherInformation.maxTemperature))) + "°" + "C")
                                } else {
                                    Text(String(Int(round(bleManagerVal.weatherInformation.maxTemperature * 1.8 + 32))) + "°" + "F")
                                }
                            }
                            .foregroundColor(.gray)
                        }
                        Text(bleManagerVal.weatherInformation.shortDescription)
                            .foregroundColor(.gray)
                            .font(.body.weight(.semibold))
                    }
                    .padding()
                    Divider()
                    VStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(bleManagerVal.weatherForecastDays, id: \.name) { day in
                                    VStack(spacing: 6) {
                                        Text(day.name)
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14).weight(.medium))
                                        Image(systemName: getIcon(icon: Int(day.icon)))
                                            .imageScale(.large)
                                            .font(.system(size: 18).weight(.medium))
                                        VStack {
                                            if celsius {
                                                Text(String(Int(round(day.maxTemperature))) + "°")
                                                Text(String(Int(round(day.minTemperature))) + "°")
                                            } else {
                                                Text(String(Int(round(day.maxTemperature * 1.8 + 32))) + "°")
                                                Text(String(Int(round(day.minTemperature * 1.8 + 32))) + "°")
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .frame(width: 95)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                    }
                    Spacer()
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
        }
}
