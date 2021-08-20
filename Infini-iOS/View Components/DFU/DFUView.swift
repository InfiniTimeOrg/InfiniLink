//
//  DFUView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/11/21.
//

import Foundation
import SwiftUI

struct DFU_Page: View {
	
	@EnvironmentObject var bleManager: BLEManager
	@ObservedObject var dfuUpdater = DFU_Updater()
	@Environment(\.colorScheme) var colorScheme
	
	@State var openFile = false
	@State private var firmwareFilename = ""
	@State private var firmwareSelected: Bool = false
	@State private var firmwareURL: URL = URL(fileURLWithPath: "")
	@State private var updateStarted: Bool = false
	
	
	var body: some View {
		
		VStack (alignment: .leading){
			Text("Firmware Update")
				.font(.largeTitle)
				.padding()
			
			HStack {
				Text("Current Firmware: ")
					.font(.title)
				Text(bleManager.firmwareVersion)
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
				Text("Progress:")
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.horizontal)
				DFUProgressBar().environmentObject(dfuUpdater)
					.frame(height: 20 ,alignment: .center)
					.padding()
			}
			
			Button(action:{
				openFile = true
			}) {
				Text("Select Firmware File")
					.padding()
					.padding(.vertical, 7)
					.frame(maxWidth: .infinity, alignment: .center)
					.background(Color.gray)
					.foregroundColor(Color.white)
					.cornerRadius(10)
					.padding(.horizontal, 20)
			}
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
			
			if updateStarted {
				Button(action:{
					dfuUpdater.stopTransfer()
					updateStarted = false
				}) {
					Text("Stop Transfer")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(firmwareSelected ? Color.gray : Color.darkGray)
						.foregroundColor(firmwareSelected ? Color.white : Color.gray)
						.cornerRadius(10)
						.padding(.horizontal, 20)
				}.disabled(!firmwareSelected)
			} else {
				Button(action:{
					dfuUpdater.prepare(location: firmwareURL, device: bleManager)
					dfuUpdater.transfer()
					updateStarted = true
				}) {
					Text("Begin Transfer")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(firmwareSelected ? Color.gray : Color.darkGray)
						.foregroundColor(firmwareSelected ? Color.white : Color.gray)
						.cornerRadius(10)
						.padding(.horizontal, 20)
				}.disabled(!firmwareSelected)
			}
		}
	}
}
