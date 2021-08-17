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
	@ObservedObject var dfuUpdater: DFU_Updater
	
	@State var openFile = false
	@State private var firmwareFilename = ""
	@State private var firmwareSelected: Bool = false
	@State private var firmwareURL: URL = URL(fileURLWithPath: "")
	@State private var updateStarted: Bool = false
	
	
	var body: some View {
		VStack (spacing: 10){
			Text("Firmware Update")
				.font(.largeTitle)
				.frame(maxWidth: .infinity, alignment: .center)
				.padding(.bottom, 30)

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
							.padding()
							.padding(.vertical, 7)
							.frame(maxWidth: .infinity, alignment: .center)
							.background(Color.gray)
							.foregroundColor(Color.white)
							.cornerRadius(10)
							.padding(.horizontal, 20)
					}
						
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

			
			VStack (spacing:10) {
				HStack (spacing: 10){
					
				}
			}
			// using this fileImporter to grab the zip from your phone's Files app. DFU updater just wants the local URL to the file, so we're opening privileged access, grabbing the url, and closing privileged access
			.fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) {(res) in
			do{
				let fileUrl = try res.get()
				//print(fileUrl) // DEBUG
				//print("filename: ", fileUrl.lastPathComponent) // DEBUG
			   
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
		}
	}
}
