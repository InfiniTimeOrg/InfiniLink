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
                .padding(.bottom)
                VStack {
                    Divider()
                        .padding(.horizontal, -16)
                    VStack(spacing: 8) {
                        HStack {
                            ForEach(bleManagerVal.weatherInformation.forecastIcon, id: \.self) { icon in
                                Image(systemName: getIcon(icon: Int(icon)))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        HStack {
                            ForEach(bleManagerVal.weatherInformation.forecastMaxTemperature, id: \.self) { temp in
                                Group {
                                    if celsius {
                                        Text(String(Int(round(temp))) + "°")
                                    } else {
                                        Text(String(Int(round(temp * 1.8 + 32))) + "°")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        HStack {
                            ForEach(bleManagerVal.weatherInformation.forecastMinTemperature, id: \.self) { temp in
                                Group {
                                    if celsius {
                                        Text(String(Int(round(temp))) + "°")
                                    } else {
                                        Text(String(Int(round(temp * 1.8 + 32))) + "°")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .padding(.vertical)
                    Divider()
                        .padding(.horizontal, -16)
                }
                Spacer()
                Divider()
                    .padding(.horizontal, -16)
                Group {
                    if !WeatherController.shared.nwsapiFailed {
                        Text("Data from NWS")
                    } else if !WeatherController.shared.weatherapiFailed {
                        Text("Data from WeatherAPI")
                    }
                }
                .padding(8)
                .font(.system(size: 14).weight(.medium))
                .foregroundColor(.gray)
            }
            .padding()
        }
        .onAppear {
            // DEBUG
            BLEManagerVal.shared.weatherInformation.shortDescription = "Light Rain"
            BLEManagerVal.shared.weatherInformation.icon = 4
            BLEManagerVal.shared.weatherInformation.temperature = 4
            BLEManagerVal.shared.weatherInformation.maxTemperature = 3
            BLEManagerVal.shared.weatherInformation.maxTemperature = 5
            BLEManagerVal.shared.weatherInformation.forecastIcon = [4, 3, 0, 0, 4, 6, 2]
            BLEManagerVal.shared.weatherInformation.forecastMaxTemperature = [35, 31, 39, 42, 53, 41, 37]
            BLEManagerVal.shared.weatherInformation.forecastMinTemperature = [25, 22, 31, 32, 45, 36, 28]
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
            BLEManagerVal.shared.weatherInformation.forecastIcon = [4, 3, 0, 0, 4, 6, 2]
            BLEManagerVal.shared.weatherInformation.forecastMaxTemperature = [35, 31, 39, 42, 53, 41, 37]
            BLEManagerVal.shared.weatherInformation.forecastMinTemperature = [25, 22, 31, 32, 45, 36, 28]
        }
}
