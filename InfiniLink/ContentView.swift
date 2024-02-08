//
//  ContentView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

enum Tab {
    case home
    case settings
}

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var batteryNotifications = BatteryNotifications()
    @ObservedObject var sheetManager = SheetManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @ObservedObject var deviceDataForTopLevel: DeviceData = deviceData
    @State var selection: Tab = .home
    
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("onboarding") var onboarding: Bool!// = false
    @AppStorage("lastVersion") var lastVersion: String = ""
    @AppStorage("showDisconnectAlert") var showDisconnectConfDialog: Bool = false
    @AppStorage("showClearHRMChartConf") var showClearHRMChartConf: Bool = false
    @AppStorage("showClearBatteryChartConf") var showClearBatteryChartConf: Bool = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
    private var chartPoints: FetchedResults<ChartDataPoint>
    
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    
    private func switchToTab(tab: Tab) {
        if selection != tab {
            selection = tab
            
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationView {
                switch selection {
                case .home:
                    WelcomeView()
                        .alert(isPresented: $bleManager.setTimeError, content: {
                            Alert(title: Text(NSLocalizedString("failed_set_time", comment: "")), message: Text(NSLocalizedString("failed_set_time_description", comment: "")), dismissButton: .default(Text(NSLocalizedString("dismiss_button", comment: ""))))})
                        .alert(isPresented: $showDisconnectConfDialog) {
                            Alert(title: Text(NSLocalizedString("disconnect_alert_title", comment: "")), primaryButton: .destructive(Text(NSLocalizedString("disconnect", comment: "Disconnect")), action: bleManager.disconnect), secondaryButton: .cancel())
                        }
                        .alert(isPresented: $showClearHRMChartConf) {
                            Alert(title: Text(NSLocalizedString("clear_chart_data_alert_title", comment: "")), primaryButton: .destructive(Text(NSLocalizedString("continue", comment: "Continue")), action: {
                                ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
                            }), secondaryButton: .cancel())
                        }
                        .alert(isPresented: $showClearBatteryChartConf) {
                            Alert(title: Text(NSLocalizedString("clear_chart_data_alert_title", comment: "")), primaryButton: .destructive(Text(NSLocalizedString("continue", comment: "Continue")), action: {
                                ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
                                ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.connected.rawValue)
                                ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: bleManager.batteryLevel, chart: ChartsAsInts.battery.rawValue))
                            }), secondaryButton: .cancel())
                        }
                case .settings:
                    Settings_Page()
                }
            }
            tabBar
        }
        .sheet(isPresented: $sheetManager.showSheet, content: {
            SheetManager.CurrentSheet()
                .onDisappear {
                    if !sheetManager.upToDate {
                        if onboarding == nil {
                            onboarding = false
                        }
                    }
                }
        })
        .onAppear {
            if !bleManager.isConnectedToPinetime {
                if bleManager.isSwitchedOn {
                    self.bleManager.startScanning()
                }
            }
        }
        .preferredColorScheme((deviceDataForTopLevel.chosenTheme == "System") ? nil : appThemes[deviceDataForTopLevel.chosenTheme])
        .onChange(of: bleManager.batteryLevel) { bat in
            batteryNotifications.notify(bat: Int(bat), bleManager: bleManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification), perform: { output in
            if bleManager.isConnectedToPinetime {
                ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: 0, chart: ChartsAsInts.connected.rawValue))
            }
        })
    }
    
    var tabBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                TabBarItem(selection: $selection, tab: .home, imageName: "house")
                    .onTapGesture {
                        switchToTab(tab: .home)
                    }
                    .frame(maxWidth: .infinity)
                
                TabBarItem(selection: $selection, tab: .settings, imageName: "gear")
                    .onTapGesture {
                        switchToTab(tab: .settings)
                    }
                    .frame(maxWidth: .infinity)
            }
            .padding(12)
        }
    }
}

struct TabBarItem: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selection: Tab
    let tab: Tab
    let imageName: String
    
    var body: some View {
        if selection == tab {
            HStack {
                Image(systemName: imageName)
                Text(tab == .home ? NSLocalizedString("home", comment: "") : NSLocalizedString("settings", comment: ""))
            }
            .imageScale(.large)
            .font(.body.weight(.semibold))
            .foregroundColor(colorScheme == .dark ? .white : .darkestGray)
            .cornerRadius(10)
            .padding(8)
        } else {
            HStack {
                Image(systemName: imageName)
                Text(tab == .home ? NSLocalizedString("home", comment: "") : NSLocalizedString("settings", comment: ""))
            }
            .foregroundColor(Color.gray)
            .imageScale(.large)
            .padding(8)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BLEManager())
        .environmentObject(DFU_Updater())
}

let deviceData: DeviceData = DeviceData()
