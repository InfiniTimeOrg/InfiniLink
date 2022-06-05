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


struct ContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var batteryNotifications = BatteryNotifications()
    @ObservedObject var sheetManager = SheetManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @ObservedObject var deviceDataForTopLevel: DeviceData = deviceData
    @State var selection: Int = 4
    
    
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("onboarding") var onboarding: Bool!// = false
    @AppStorage("lastVersion") var lastVersion: String = ""
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    
    
    init() {
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont.systemFont(ofSize: 18.0, weight: .bold)]
    }
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                WelcomeView()
                    .alert(isPresented: $bleManager.setTimeError, content: {
                            Alert(title: Text(NSLocalizedString("failed_set_time", comment: "")), message: Text(NSLocalizedString("failed_set_time_description", comment: "")), dismissButton: .default(Text(NSLocalizedString("dismiss_button", comment: ""))))})
                
                    .navigationBarItems(leading: ( HStack { if bleManager.isConnectedToPinetime && deviceInfo.firmware != "" { Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f",   bleManager.batteryLevel))! / 25) * 25))).imageScale(.large)}}))
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text(NSLocalizedString("home", comment: ""))
            }
            .tag(0)

            NavigationView {
                ChartView()
                    .navigationBarItems(leading: ( HStack { if bleManager.isConnectedToPinetime && deviceInfo.firmware != "" { Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f",   bleManager.batteryLevel))! / 25) * 25))).imageScale(.large)}}))
                    .navigationBarTitle(Text(NSLocalizedString("charts", comment: "")).font(.subheadline), displayMode: .large)
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text(NSLocalizedString("charts", comment: ""))
            }
            .tag(1)
            
            NavigationView {
                Settings_Page()
                    .navigationBarItems(leading: ( HStack { if bleManager.isConnectedToPinetime && deviceInfo.firmware != "" { Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f",   bleManager.batteryLevel))! / 25) * 25))).imageScale(.large)}}))
                    .navigationBarTitle(Text(NSLocalizedString("settings", comment: "")).font(.subheadline), displayMode: .large)
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text(NSLocalizedString("settings", comment: ""))
            }
            .tag(2)
        }
        // if autoconnect is set, start scan ASAP, but give bleManager half a second to start up
        .sheet(isPresented: $sheetManager.showSheet, content: { SheetManager.CurrentSheet().onDisappear { if !sheetManager.upToDate { if onboarding == nil { onboarding = false } //;sheetManager.setNextSheet(autoconnect: autoconnect, autoconnectUUID: autoconnectUUID)
        }} })
        .onAppear() { if !bleManager.isConnectedToPinetime { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { if autoconnect && bleManager.isSwitchedOn { self.bleManager.startScanning() }
            
        }) }}
        .preferredColorScheme((deviceDataForTopLevel.chosenTheme == "System Default") ? nil : appThemes[deviceDataForTopLevel.chosenTheme])
        .onChange(of: bleManager.batteryLevel) { bat in
            batteryNotifications.notify(bat: Int(bat), bleManager: bleManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification), perform: { output in
            if bleManager.isConnectedToPinetime {
                ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: 0, chart: ChartsAsInts.connected.rawValue))
            }
        })
    }
}


    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BLEManager())
            .environmentObject(DFU_Updater())
    }
}
                

let deviceData: DeviceData = DeviceData()
