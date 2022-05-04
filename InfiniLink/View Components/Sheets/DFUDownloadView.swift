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
//		.onAppear(){
//			DownloadManager.shared.getDownloadUrls()
//		}
	}
}
