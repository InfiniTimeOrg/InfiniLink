//
//  DFUView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import SwiftUI

struct DFU_Page: View {
	
	@EnvironmentObject var bleManager: BLEManager
	@ObservedObject var dfuUpdater: DFU_Updater//(ble: bleManager)
	@State var openFile = false
	//@State private var firmwareData = Data.init()
	@State private var firmwareFilename = ""
	@State private var firmwareSelected: Bool = false
	@State private var firmwareURL: URL = URL(fileURLWithPath: "")
	@State private var updateStarted: Bool = false
	
	
	var body: some View {
		VStack (spacing: 10){
			Text("Firmware Update")
				.font(.largeTitle)
				.frame(maxWidth: .infinity, alignment: .center)
				.padding(30)

			HStack (spacing: 10){
				Text("Current Firmware: ")
					.font(.title)
				Text(bleManager.firmwareVersion)
					.font(.title)
			}
			
			Spacer()
			
				VStack (spacing: 10){
					if firmwareSelected {
						Text("Selected Firmware File: ")
							.font(.title)
						Text(firmwareFilename)
					}
					if updateStarted{
						HStack (spacing: 10){
							Text("Transfer Status: ")
								.font(.title)
							Text(String(dfuUpdater.percentComplete))
								.font(.title)
							Text("%")
								.font(.title)
						}
					}
					Spacer()
				
					Button(action:{
						openFile = true
					}) {
						Text("Select Firmware File")
							.padding(10)
					}
					.background(Color.gray)
					.foregroundColor(Color.white)
					.cornerRadius(5)
						
					Button(action:{
						dfuUpdater.prepare(location: firmwareURL, device: bleManager)
						dfuUpdater.transfer()
						updateStarted = true
					}) {
						Text("Begin Transfer")
							.padding(10)
					}.disabled(!firmwareSelected)
					.background(Color.gray)
					.foregroundColor(Color.white)
					.cornerRadius(5)
				}

			
			VStack (spacing:10) {
				HStack (spacing: 10){
					
				}
			}
			.fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) {(res) in
			do{
				let fileUrl = try res.get()
				print(fileUrl)
				print("filename: ", fileUrl.lastPathComponent)
			   
				guard fileUrl.startAccessingSecurityScopedResource() else { return }
				
				//let firmwareZip = try Data(contentsOf: fileUrl)
				//self.firmwareData = firmwareZip
				self.firmwareSelected = true
				self.firmwareFilename = fileUrl.lastPathComponent
				self.firmwareURL = fileUrl.absoluteURL
				
				fileUrl.stopAccessingSecurityScopedResource()
		   } catch{
				print ("error reading")
				print (error.localizedDescription)
			}
		}
		}
	}
}
