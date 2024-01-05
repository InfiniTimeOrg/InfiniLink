//
//  ContentView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

struct BatteryIcon: View {
    @ObservedObject var bleManager = BLEManager.shared
    var body: some View{
        HStack {
            Text(String(format: "%.0f", bleManager.batteryLevel) + "%")
                .font(.system(size: 15))
            Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f", bleManager.batteryLevel))! / 25) * 25)))
                .imageScale(.large)
        }
        .offset(x: -18, y: -5)
    }
}

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
    
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    
    private func switchToTab(tab: Tab) {
        selection = tab
        
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
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
