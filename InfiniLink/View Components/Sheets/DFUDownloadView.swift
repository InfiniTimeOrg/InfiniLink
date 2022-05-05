//
//  DFUDownloadView.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/24/21.
//  
//
    

import Foundation
import SwiftUI

struct DownloadView: View {
	@ObservedObject var downloadManager = DownloadManager.shared
	@ObservedObject var dfuUpdater = DFU_Updater.shared
	@Environment(\.presentationMode) var presentation
    @Binding var openFile: Bool
    
	var body: some View {
		VStack {
			//HStack {
			//	Text("Available Downloads")
			//		.font(.largeTitle)
			//		.padding()
			//		.frame(maxWidth: .infinity, alignment: .leading)
			//	Button {
			//		DownloadManager.shared.getDownloadUrls()
			//	} label: {
			//		Image(systemName: "arrow.counterclockwise")
			//			.padding()
			//			.imageScale(.large)
			//	}
			//}
			List{
                Section(header: Text("Firmware File Link")) {
                    Button {
                        openFile.toggle()
                        
                        //dfuUpdater.firmwareFilename = "Local File"
                        //dfuUpdater.firmwareSelected = true
                        dfuUpdater.local = true
                        downloadManager.updateAvailable = true
                        //downloadManager.updateVersion = i.tag_name
                        downloadManager.updateBody = ""
                        downloadManager.updateSize = 0
                        //downloadManager.browser_download_url = asset.browser_download_url
                    } label: {
                        Text("Select Local File")
                    }
                }
				Section(header: Text("Firmware Download Links")) {
					ForEach(downloadManager.results, id: \.tag_name) { i in
						Button {
                            let asset = downloadManager.chooseAsset(response: i)
                            //downloadManager.setupTest(firFile: asset.name)
                            
                            //DFU_Updater.shared.firmwareFilename = asset.name
                            dfuUpdater.firmwareFilename = asset.name
							dfuUpdater.firmwareSelected = true
							dfuUpdater.local = false
                            downloadManager.updateAvailable = true
                            downloadManager.updateVersion = i.tag_name
                            downloadManager.updateBody = i.body
                            downloadManager.updateSize = asset.size
                            downloadManager.browser_download_url = asset.browser_download_url
							presentation.wrappedValue.dismiss()
						} label: {
							Text(i.tag_name)
						}

					}
				}

			}
			Spacer()
		}.navigationBarItems(trailing: (
            Button(action: {downloadManager.getDownloadUrls(currentVersion: BLEDeviceInfo.shared.firmware)}) {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.large)
            }
        ))
        .navigationBarTitle(Text("Downloads").font(.subheadline), displayMode: .inline)
        .fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) {(res) in
            // this fileImporter allows user to select the zip from local storage. DFU updater just wants the local URL to the file, so we're opening privileged access, grabbing the url, and closing privileged access
            do{
                let fileUrl = try res.get()
                
                guard fileUrl.startAccessingSecurityScopedResource() else { return }
        
                dfuUpdater.firmwareSelected = true
                dfuUpdater.firmwareFilename = fileUrl.lastPathComponent
                dfuUpdater.firmwareURL = fileUrl.absoluteURL
                
                fileUrl.stopAccessingSecurityScopedResource()
                presentation.wrappedValue.dismiss()
            } catch{
                DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
            }
        }
//		.onAppear(){
//			DownloadManager.shared.getDownloadUrls()
//		}
	}
}
