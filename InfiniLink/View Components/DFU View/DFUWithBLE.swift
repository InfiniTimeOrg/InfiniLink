//
//  DFUWithBLE.swift
//  DFUWithBLE
//
//  Created by Alex Emry on 9/15/21.
//  
//


import Foundation
import SwiftUI

extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}

struct DFUWithBLE: View {
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject var deviceInfo = BLEDeviceInfo.shared
	@ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var downloadManager = DownloadManager.shared
	
	@State var openFile = false
	
	
	var body: some View {
		ZStack {
			VStack (alignment: .leading) {
				List {
                    
                    if downloadManager.updateAvailable && dfuUpdater.firmwareSelected {
                        NewUpdate(updateStarted: $downloadManager.updateStarted, openFile: $openFile)
                    } else {
                        NoUpdate(openFile: $openFile)
                    }
				}
                .listStyle(.insetGrouped)
			}
            .fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) {(res) in
                // this fileImporter allows user to select the zip from local storage. DFU updater just wants the local URL to the file, so we're opening privileged access, grabbing the url, and closing privileged access
                do{
                    let fileUrl = try res.get()
                    
                    guard fileUrl.startAccessingSecurityScopedResource() else { return }
                    
                    dfuUpdater.firmwareSelected = true
                    dfuUpdater.firmwareFilename = fileUrl.lastPathComponent
                    dfuUpdater.firmwareURL = fileUrl.absoluteURL
                    
                    fileUrl.stopAccessingSecurityScopedResource()
                } catch{
                    DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
                }
            }
			VStack{
				if dfuUpdater.transferCompleted {
					DFUComplete()
						.cornerRadius(10)
						.onAppear() {
							DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
								dfuUpdater.transferCompleted = false
							})
                            downloadManager.updateStarted = false
							dfuUpdater.firmwareURL = URL(fileURLWithPath: "")
							dfuUpdater.firmwareSelected = false
							dfuUpdater.firmwareFilename = ""
                            downloadManager.updateAvailable = downloadManager.checkForUpdates(currentVersion: downloadManager.updateVersion)
						}
				}
			}.transition(.opacity).animation(.easeInOut(duration: 1.0))
		}
        .navigationBarItems(trailing: (
            Button(action: {downloadManager.getDownloadUrls(currentVersion: BLEDeviceInfo.shared.firmware)}) {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.large)
            }
        ))
        .navigationBarTitle(Text(NSLocalizedString("software_update", comment: "")).font(.subheadline), displayMode: .inline)
	}
}

struct ClearSelectedFirmwareHeader: View {
	@ObservedObject var dfuUpdater = DFU_Updater.shared
	var body: some View {
		HStack{
			Text("Firmware File")
			Spacer()
			if dfuUpdater.firmwareSelected {
				Button{
					dfuUpdater.firmwareURL = URL(fileURLWithPath: "")
					dfuUpdater.firmwareSelected = false
					dfuUpdater.firmwareFilename = ""
				} label: {
					Text("Clear")
				}
			}
		}
	}
}

struct NewUpdate: View {
    @Binding var updateStarted: Bool
    //@ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    @Environment(\.colorScheme) var scheme
    @Binding var openFile: Bool
    
    //@State var updateStarted: Bool = false
    
    var body: some View {
        Section() {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image("InfiniTime")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                        .frame(width: 75, height: 75)
                    VStack(alignment: .leading) {
                        if dfuUpdater.local == false {
                            Text("InfiniTime \(DownloadManager.shared.updateVersion)")
                                .bold()
                        } else {
                            Text(dfuUpdater.firmwareFilename)
                                .bold()
                        }
                        Text("\(Int(ceil(Double(DownloadManager.shared.updateSize) / 1000.0))) KB")
                            .font(.caption)
                        if updateStarted {
                            DFUProgressBar().environmentObject(dfuUpdater)
                                //.frame(height: 40 ,alignment: .center)
                                //.padding()
                        }
                    }
                    .padding(5)
                }
                HStack {
                    if dfuUpdater.local == false {
                        Text(DownloadManager.shared.updateBody)
                            .font(.system(size: 14))
                            .lineLimit(3)
                            .padding(5)
                    } else {
                        Text(NSLocalizedString("local_file_info", comment: ""))
                            .font(.system(size: 14))
                            .lineLimit(3)
                            .padding(5)
                    }
                }
                
            }.frame(height: 160 ,alignment: .center)
            
            if dfuUpdater.local == false {
                NavigationLink(destination: DFULearnMore()) {
                    Text(NSLocalizedString("learn_more", comment: ""))
                }
            }
        }
        Section() {
            DFUStartTransferButton(updateStarted: $updateStarted, firmwareSelected: $dfuUpdater.firmwareSelected)
            //Button("Download and Install", action: {})
            
            if !(UserDefaults.standard.value(forKey: "showNewDownloadsOnly") as? Bool ?? true) {
                NavigationLink(destination: DownloadView(openFile: $openFile)) {
                    Text(NSLocalizedString("install_older_version", comment: ""))
                }
            }
        }
    }
}

struct NoUpdate: View {
    //@ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var openFile: Bool
    
    var body: some View {
        if !(UserDefaults.standard.value(forKey: "showNewDownloadsOnly") as? Bool ?? true) {
            Section() {
                NavigationLink(destination: DownloadView(openFile: $openFile)) {
                    Text(NSLocalizedString("install_older_version", comment: ""))
                }
            }
        }
        
        Section() {
            VStack(spacing: 5) {
                VStack(alignment: .center) {
                    Text("InfiniTime \(deviceInfo.firmware)")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                    Text("InfiniTime " + NSLocalizedString("up_to_date", comment: ""))
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
            .padding(5)
        }
        .frame(height: UIScreen.screenHeight / 2.0)
        .listRowBackground(Color.clear)
    }
}
