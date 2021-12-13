//
//  DFUWithBLE.swift
//  DFUWithBLE
//
//  Created by Alex Emry on 9/15/21.
//  
//


import Foundation
import SwiftUI

struct DFUWithBLE: View {
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var deviceInfo = BLEDeviceInfo.shared
	@ObservedObject var dfuUpdater = DFU_Updater.shared
	
	@State var openFile = false
	@State private var updateStarted: Bool = false
	
	
	var body: some View {
		ZStack {
			VStack (alignment: .leading){
				Text(NSLocalizedString("update_firmware", comment: ""))
					.font(.largeTitle)
					.padding()
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
				List {
					Section(header: Text(NSLocalizedString("current_firmware", comment: ""))) {
						Text(deviceInfo.firmware)
					}
					Section(header: ClearSelectedFirmwareHeader()) {
						if dfuUpdater.firmwareSelected {
							Text(dfuUpdater.firmwareFilename)
						} else {
							DFUFileSelectButton(openFile: $openFile)
						}
					}
				}
					.listStyle(.inset)
				
				Spacer()
				
				if updateStarted {
					DFUProgressBar().environmentObject(dfuUpdater)
						.frame(height: 40 ,alignment: .center)
						.padding()
				}
					
				DFUStartTransferButton(updateStarted: $updateStarted, firmwareSelected: $dfuUpdater.firmwareSelected)
			}
			VStack{
				if dfuUpdater.transferCompleted {
					DFUComplete()
						.cornerRadius(10)
						.onAppear() {
							DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
								dfuUpdater.transferCompleted = false
							})
							updateStarted = false
							dfuUpdater.firmwareURL = URL(fileURLWithPath: "")
							dfuUpdater.firmwareSelected = false
							dfuUpdater.firmwareFilename = ""
						}
				}
			}.transition(.opacity).animation(.easeInOut(duration: 1.0))
		}
	}
}

struct ClearSelectedFirmwareHeader: View {
	@ObservedObject var dfuUpdater = DFU_Updater.shared
	var body: some View {
		HStack{
			Text(NSLocalizedString("firmware_file", comment: ""))
			Spacer()
			if dfuUpdater.firmwareSelected {
				Button{
					dfuUpdater.firmwareURL = URL(fileURLWithPath: "")
					dfuUpdater.firmwareSelected = false
					dfuUpdater.firmwareFilename = ""
				} label: {
					Text(NSLocalizedString("clear", comment: ""))
				}
			}
		}
	}
}
