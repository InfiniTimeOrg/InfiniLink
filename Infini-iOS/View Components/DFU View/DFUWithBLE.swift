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
	@EnvironmentObject var dfuUpdater: DFU_Updater
	
	@State var openFile = false
	@State private var firmwareFilename = ""
	@State private var firmwareSelected: Bool = false
	@State private var firmwareURL: URL = URL(fileURLWithPath: "")
	@State private var updateStarted: Bool = false
	
	var body: some View {
		ZStack {
			VStack (alignment: .leading){
				Text("Update Firmware")
					.font(.largeTitle)
					.padding()
				
				HStack {
					Text("Current Firmware: ")
						.font(.title)
					Text(deviceInfo.firmware)
						.font(.title)
				}.padding()
				
				
				if firmwareSelected {
					Text("Selected Firmware File: ")
						.font(.title)
						.padding(.horizontal)
					Text(firmwareFilename)
						.padding(.horizontal)
				}
				Spacer()
				
				if updateStarted {
					DFUProgressBar().environmentObject(dfuUpdater)
						.frame(height: 40 ,alignment: .center)
						.padding()
				}
				
				DFUFileSelectButton(openFile: $openFile)
					.environmentObject(bleManager)
					.fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) {(res) in
						// this fileImporter allows user to select the zip from local storage. DFU updater just wants the local URL to the file, so we're opening privileged access, grabbing the url, and closing privileged access
						do{
							let fileUrl = try res.get()
							
							guard fileUrl.startAccessingSecurityScopedResource() else { return }
							
							self.firmwareSelected = true
							self.firmwareFilename = fileUrl.lastPathComponent
							self.firmwareURL = fileUrl.absoluteURL
							
							fileUrl.stopAccessingSecurityScopedResource()
						} catch{
							print ("error reading")
							print (error.localizedDescription)
						}
					}
				DFUStartTransferButton(updateStarted: $updateStarted, firmwareSelected: $firmwareSelected, firmwareURL: $firmwareURL)
					.environmentObject(dfuUpdater)
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
							firmwareURL = URL(fileURLWithPath: "")
							firmwareSelected = false
							firmwareFilename = ""
							bleManager.disconnect()
						}
				}
			}.transition(.opacity).animation(.easeInOut(duration: 1.0))
		}
	}
}
