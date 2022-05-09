//
//  HomeScreen.swift
//  HomeScreen
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import SwiftUI


struct HomeScreen: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("debugMode") var debugMode: Bool = false
    @AppStorage("favorites") var favorites: Array = ["Steps", "Heart"]
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
                                            Text(NSLocalizedString("scanning", comment: ""))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .bold()
                                                .font(.system(size: 20))
                                        } else {
                                            Text(NSLocalizedString("disconnect", comment: ""))
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
                                            Text(NSLocalizedString("firmware_version", comment: "") + deviceInfo.firmware)
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
                                            Text(NSLocalizedString("model", comment: "")  + String(deviceInfo.modelNumber))
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
                                Text(NSLocalizedString("firmware_update_is_available", comment: ""))
                            }
                        }
                    //}
                }
                
                
                //Section(header: Text("Favorites")
                //            .font(.system(size: 14))
                //            .bold()
                //            .padding(1)) {
                //    Widget(widgetName: "Steps")
                //    //StepFavorite()
                //}
                
                ForEach(favorites, id: \.self) { user in
                    if favorites.firstIndex(of: user)! == 0 {
                        Section(header: Text("Favorites")
                                    .font(.system(size: 14))
                                    .bold()
                                    .padding(1)) {
                            Widget(widgetName: user)
                        }
                    } else {
                        Section {
                            Widget(widgetName: user)
                        }
                    }
                }
                
                //.onAppear { UITableView.appearance().separatorStyle = .none }
                
                //Section {
                //    Widget(widgetName: "Heart")
                //    //HeartWidget()
                //}
                
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

