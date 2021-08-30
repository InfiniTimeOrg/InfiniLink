//
//  DFUView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import SwiftUI

struct DFUView: View {
	
	@EnvironmentObject var bleManager: BLEManager
	@EnvironmentObject var dfuUpdater: DFU_Updater
	@Environment(\.colorScheme) var colorScheme
	
	@State var openFile = false
	@State private var firmwareFilename = ""
	@State private var firmwareSelected: Bool = false
	@State private var firmwareURL: URL = URL(fileURLWithPath: "")
	@State private var updateStarted: Bool = false
	
	
	var body: some View {
		ZStack {
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
					DFUProgressBar().environmentObject(dfuUpdater)
						.frame(height: 40 ,alignment: .center)
						.padding()
				}
				
				Button(action:{
					openFile = true
				}) {
					Text("Select Firmware File")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(colorScheme == .dark ? Color.darkGray : Color.gray)
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
							.background(colorScheme == .dark ? (firmwareSelected ? Color.darkGray : Color.darkestGray) : (firmwareSelected ? Color.gray : Color.lightGray))
							.foregroundColor(firmwareSelected ? Color.white : Color.gray)
							.cornerRadius(10)
							.padding(.horizontal, 20)
							.padding(.bottom)
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
							.background(colorScheme == .dark ? (firmwareSelected ? Color.darkGray : Color.darkestGray) : (firmwareSelected ? Color.gray : Color.lightGray))
							.foregroundColor(firmwareSelected ? Color.white : Color.gray)
							.cornerRadius(10)
							.padding(.horizontal, 20)
							.padding(.bottom)
					}.disabled(!firmwareSelected)
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
							updateStarted = false
							firmwareURL = URL(fileURLWithPath: "")
							firmwareSelected = false
							firmwareFilename = ""
						}
				}
			}.transition(.opacity).animation(.easeInOut(duration: 1.0))
		}
	}
}

struct DFUView_Previews: PreviewProvider {
	static var previews: some View {
		DFUView()
			.environmentObject(BLEManager())
			.environmentObject(DFU_Updater())
	}
}
