//
//  HomeScreen.swift
//  HomeScreen
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import SwiftUI


struct StepsWidget: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: StepView()) {
            VStack {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                    Text("Steps")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    //bleManager.stepCount
                    Text(String(bleManagerVal.stepCount))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text("with a goal of \(stepCountGoal)")
                        .foregroundColor(.gray)
                        .bold()
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}


struct HeartFavorite: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: HeartView()) {
            VStack {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Heart Rate")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    Text(String(Int(bleManagerVal.heartBPM)))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text("BPM")
                        .foregroundColor(.gray)
                        .bold()
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}


struct HomeScreen: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("debugMode") var debugMode: Bool = false
    //@ObservedObject var pageSwitcher: PageSwitcher = PageSwitcher.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    //@ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var bleManager = BLEManager.shared
    //@ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var uptimeManager = UptimeManager.shared
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State var currentUptime: TimeInterval!
    @State var updateAvailable: Bool = false
    
    //@State var renamingDevice: Bool = false
    //@State private var changedName: String = ""
    //private var nameManager = DeviceNameManager()
    //@State private var deviceName = ""
    
    //func changePage(newPage: Page) {
    //    pageSwitcher.currentPage = newPage
    //    withAnimation() {
    //        pageSwitcher.showMenu = false
    //    }
    //}
    
    private var dateFormatter = DateComponentsFormatter()
    
    var body: some View {
        return VStack {
            //HStack {
            //    if false {
            //        Text("Micah's InfiniTime")
            //            .font(.system(size: 18))
            //            .padding(15)
            //            .frame(maxWidth: .infinity, alignment: .leading)
            //        HStack {
            //            Text(String(format: "%.0f", bleManager.batteryLevel) + "%")
            //                .font(.system(size: 16))
            //            Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f", bleManager.batteryLevel))! / 25) * 25)))
            //                .imageScale(.large)
            //        }
            //        .padding(15)
            //        .frame(alignment: .trailing)
            //    } else {
            //        //Text("")
            //    }
            //}
            List() {
                Section(header: Text("My Device")
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
                    //NavigationLink(destination: DeviceView()) {
                        HStack(spacing: 5) {
                            Image("PineTime-1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(5)
                                .frame(width: 110, height: 110)
                            
                            Spacer()
                            VStack(alignment: .leading) {
                                if !bleManager.isConnectedToPinetime || deviceInfo.firmware == "" {
                                    Button() {
                                        if !bleManager.isConnectedToPinetime {
                                            SheetManager.shared.sheetSelection = .connect
                                            SheetManager.shared.showSheet = true
                                        }
                                    } label: {
                                        if bleManager.isConnectedToPinetime {
                                            Text("Connecting...")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .bold()
                                                .font(.system(size: 20))
                                        } else {
                                            Text("Not Connected")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .bold()
                                                .font(.system(size: 20))
                                            //.padding(1)
                                            Text("Tap to connect")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .font(.system(size: 12))
                                            Text("")
                                                .font(.system(size: 12))
                                        }
                                    }
                                } else {
                                    NavigationLink(destination: DeviceView()) {
                                        VStack(alignment: .leading) {
                                            Text(deviceInfo.deviceName)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .bold()
                                                .font(.system(size: 20))
                                            Text("Firmware Version: " + deviceInfo.firmware)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .font(.system(size: 12))
                                                .onAppear() {
                                                    // check if an update has been made in the last //24 hours
                                                    if DownloadManager.shared.lastCheck == nil || DownloadManager.shared.lastCheck.timeIntervalSince(Date()) <  -86400 {
                                                        DownloadManager.shared.getDownloadUrls(currentVersion: BLEDeviceInfo.shared.firmware)
                                                        DownloadManager.shared.lastCheck = Date()
                                                    } else {
                                                        DownloadManager.shared.updateAvailable = DownloadManager.shared.checkForUpdates(currentVersion: BLEDeviceInfo.shared.firmware)
                                                    }
                                                }
                                            Text("Model: \(deviceInfo.modelNumber)")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .font(.system(size: 12))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(5)
                    //}
                }
                
                if bleManager.isConnectedToPinetime {
                    //if !DownloadManager.shared.downloading {
                        if DownloadManager.shared.updateAvailable {
                            NavigationLink(destination: DFUView()) {
                                Text("Update Available")
                            }
                        }
                    //}
                }
                
                
                Section(header: Text("Favorites")
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
                    StepsWidget()
                    //StepFavorite()
                }
                
                //.onAppear { UITableView.appearance().separatorStyle = .none }
                
                Section {
                    HeartFavorite()
                }
                
                NavigationLink(destination: CustomizeFavoritesView()) {
                    Text("Customize Favorites")
                }
                
                //Section {
                //    NavigationLink(destination: Settings_Page()) {
                //        Text("More Settings")
                //    }
                //}
                
                
              
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitle(Text("InfiniLink").font(.subheadline), displayMode: .large)
    }
}

