//
//  SettingsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/15/21.
//
//


import Foundation
import SwiftUI
import CoreLocation

struct Settings_Page: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var weatherController = WeatherController.shared
    
    @ObservedObject private var deviceDataForSettings: DeviceData = deviceData
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.managedObjectContext) var viewContext
    
    @AppStorage("watchNotifications") var watchNotifications: Bool = true
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("heartChartFill") var heartChartFill: Bool = true
    @AppStorage("batChartFill") var batChartFill: Bool = true
    @AppStorage("debugMode") var debugMode: Bool = false
    @AppStorage("weatherData") var weatherData: Bool = true
    @AppStorage("useCurrentLocation") var useCurrentLocation: Bool = true
    @AppStorage("displayLocation") var displayLocation : String = "Cupertino"
    @AppStorage("showClearHRMChartConf") var showClearHRMChartConf: Bool = false
    @AppStorage("showClearBatteryChartConf") var showClearBatteryChartConf: Bool = false
    @AppStorage("showClearStepsChartConf") var showClearStepsChartConf: Bool = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
    private var chartPoints: FetchedResults<ChartDataPoint>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var stepCounts: FetchedResults<StepCounts>
    
    let themes: [String] = ["System", "Light", "Dark"]
    let weatherModes: [String] = ["System", "Metric", "Imperial"]
    
    private let nameManager = DeviceNameManager()
    private let locationManager = CLLocationManager()
    
    var body: some View {
        VStack(spacing: 0) {
            Text(NSLocalizedString("settings", comment: ""))
                .foregroundColor(.primary)
                .font(.title.weight(.bold))
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 8) {
                        Menu {
                            Picker("", selection: $deviceDataForSettings.chosenTheme) {
                                ForEach(themes, id: \.self) {
                                    Text($0)
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(NSLocalizedString("app_theme", comment: ""))
                                        .font(.title3.weight(.semibold))
                                    Text(deviceDataForSettings.chosenTheme)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.medium))
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        Menu {
                            Button(action: {
                                if let url = URL(string: "https://github.com/InfiniTimeOrg/InfiniTime") {
                                    openURL(url)
                                }
                            }) {
                                Text("InfiniTime")
                            }
                            Button(action: {
                                if let url = URL(string: "https://github.com/InfiniTimeOrg/InfiniLink") {
                                    openURL(url)
                                }
                            }) {
                                Text("InfiniLink")
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("GitHub")
                                        .font(.title3.weight(.semibold))
                                    Text(NSLocalizedString("links", comment: "Links"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.medium))
                            }
                            .padding()
                            .background(Color.darkestGray)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                    VStack {
                        Toggle(NSLocalizedString("enable_debug_mode", comment: ""), isOn: $debugMode.animation(.bouncy))
                            .modifier(RowModifier(style: .capsule))
                        if debugMode {
                            NavigationLink(destination: DebugView()) {
                                HStack {
                                    Text(NSLocalizedString("debug_logs", comment: ""))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .modifier(RowModifier(style: .capsule))
                            }
                        }
                    }
                    Spacer()
                        .frame(height: 6)
                    VStack {
                        Toggle(NSLocalizedString("filled_hrm_graph", comment: ""), isOn: $heartChartFill)
                            .modifier(RowModifier(style: .capsule))
                        Toggle(NSLocalizedString("filled_battery_graph", comment: ""), isOn: $batChartFill)
                            .modifier(RowModifier(style: .capsule))
                    }
                    Spacer()
                        .frame(height: 6)
                    VStack {
                        Toggle(NSLocalizedString("enable_weather_data", comment: ""), isOn: $weatherData)
                            .onChange(of: weatherData) { value in
                                if value {
                                    weatherController.tryRefreshingWeatherData()
                                }
                            }
                            .modifier(RowModifier(style: .capsule))
                        if weatherData {
                            Toggle(NSLocalizedString("use_current_location", comment: ""), isOn: $useCurrentLocation)
                                .modifier(RowModifier(style: .capsule))
                                .onChange(of: useCurrentLocation) { value in
                                    if value {
                                        weatherController.tryRefreshingWeatherData()
                                    }
                                }
                            if locationManager.authorizationStatus == .authorizedWhenInUse && useCurrentLocation{
                                Button {
                                    locationManager.requestAlwaysAuthorization()
                                } label: {
                                    Text(NSLocalizedString("always_allow_location_services", comment: ""))
                                        .modifier(NeumorphicButtonModifer(bgColor: colorScheme == .dark ? Color.darkGray : Color.lightGray))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            NavigationLink(destination: WeatherSetLocationView()) {
                                HStack {
                                    Text(NSLocalizedString("set_location", comment: ""))
                                    Text(displayLocation)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .modifier(RowModifier(style: .capsule))
                            }
                            .opacity(!useCurrentLocation ? 1.0 : 0.5)
                            .disabled(useCurrentLocation)
                            HStack {
                                Text(NSLocalizedString("weather_style", comment: "Weather Style"))
                                Spacer()
                                Picker(deviceDataForSettings.chosenWeatherMode, selection: $deviceDataForSettings.chosenWeatherMode) {
                                    ForEach(weatherModes, id: \.self) {
                                        Text($0)
                                    }
                                }
                            }
                            .modifier(RowModifier(style: .capsule))
                        }
                    }
                    Spacer()
                        .frame(height: 6)
                    if autoconnectUUID != "" {
                        VStack {
                            Button {
                                autoconnectUUID = ""
                                bleManager.autoconnectToDevice = false
                                DebugLogManager.shared.debug(error: NSLocalizedString("autoconnect_device_cleared", comment: ""), log: .app, date: Date())
                            } label: {
                                Text(NSLocalizedString("clear_autoconnect_device", comment: ""))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .modifier(RowModifier(style: .capsule))
                            }
                            .opacity(!autoconnect || autoconnectUUID.isEmpty ? 0.5 : 1.0)
                            .disabled(!autoconnect || autoconnectUUID.isEmpty)
                        }
                        Spacer()
                            .frame(height: 6)
                    }
                    VStack {
                        Button(action: {
                            showClearHRMChartConf = true
                        }) {
                            Text(NSLocalizedString("clear_all_hrm_chart_data", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.red)
                                .modifier(RowModifier(style: .capsule))
                        }
                        .alert(isPresented: $showClearHRMChartConf) {
                            Alert(title: Text(NSLocalizedString("clear_chart_data_alert_title", comment: "")), primaryButton: .destructive(Text(NSLocalizedString("continue", comment: "Continue")), action: {
                                ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
                            }), secondaryButton: .cancel())
                        }
                        Button(action: {
                            showClearStepsChartConf = true
                        }) {
                            Text(NSLocalizedString("clear_all_steps_chart_data", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.red)
                                .modifier(RowModifier(style: .capsule))
                        }
                        .alert(isPresented: $showClearStepsChartConf) {
                            Alert(title: Text(NSLocalizedString("clear_chart_data_alert_title", comment: "")), primaryButton: .destructive(Text(NSLocalizedString("continue", comment: "Continue")), action: {
                                ChartManager.shared.deleteAllSteps(dataSet: stepCounts)
                            }), secondaryButton: .cancel())
                        }
                        Button(action: {
                            showClearBatteryChartConf = true
                        }) {
                            Text(NSLocalizedString("clear_all_battery_chart_data", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.red)
                                .modifier(RowModifier(style: .capsule))
                        }
                        .alert(isPresented: $showClearBatteryChartConf) {
                            Alert(title: Text(NSLocalizedString("clear_chart_data_alert_title", comment: "")), primaryButton: .destructive(Text(NSLocalizedString("continue", comment: "Continue")), action: {
                                ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
                                ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.connected.rawValue)
                                ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: bleManager.batteryLevel, chart: ChartsAsInts.battery.rawValue))
                            }), secondaryButton: .cancel())
                        }
                    }
                    Spacer()
                        .frame(height: 6)
                    VStack {
                        Button {
                            SheetManager.shared.sheetSelection = .onboarding
                            SheetManager.shared.showSheet = true
                        } label: {
                            Text(NSLocalizedString("open_onboarding_page", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.blue)
                                .modifier(RowModifier(style: .capsule))
                        }
                        Button {
                            SheetManager.shared.sheetSelection = .whatsNew
                            SheetManager.shared.showSheet = true
                        } label: {
                            Text(NSLocalizedString("whats_new_page_this_version", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.blue)
                                .modifier(RowModifier(style: .capsule))
                        }
                    }
                }
                .padding()
            }
        }
    }
}
