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
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var uptimeManager = UptimeManager.shared
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    @State var currentUptime: TimeInterval!
    @State var updateAvailable: Bool = false
    private var dateFormatter = DateComponentsFormatter()
    
    var body: some View {
        return VStack {
            List() {
                Section(header: Text(NSLocalizedString("my_device", comment: ""))
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
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
                                        Text(NSLocalizedString("tap_to_connect", comment: ""))
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
                }
            
                if bleManager.isConnectedToPinetime {
                    if DownloadManager.shared.updateAvailable {
                        NavigationLink(destination: DFUView()) {
                            Text(NSLocalizedString("firmware_update_is_available", comment: ""))
                        }
                    }
                }
                
                ForEach(favorites, id: \.self) { user in
                    if favorites.firstIndex(of: user)! == 0 {
                        Section(header: Text(NSLocalizedString("favorites", comment: ""))
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
                
                NavigationLink(destination: CustomizeFavoritesView()) {
                    Text(NSLocalizedString("customize_favorites", comment: ""))
                }
              
            }
            .listStyle(.insetGrouped)
        }
		.navigationBarTitle(Text("InfiniLink")) //.font(.subheadline), displayMode: .large)
    }
}

