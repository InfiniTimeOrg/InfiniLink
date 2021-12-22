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
			HStack {
				Text(NSLocalizedString("available_downloads", comment: ""))
					.font(.largeTitle)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
				Button {
					DownloadManager.shared.getDownloadUrls()
				} label: {
					Image(systemName: "arrow.counterclockwise")
						.padding()
						.imageScale(.large)
				}
			}
			List{
				Section(header: Text(NSLocalizedString("firmware_download_links", comment: ""))) {
					ForEach(downloadManager.results, id: \.tag_name) { i in
						Button {
							let asset = downloadManager.chooseAsset(response: i)
							dfuUpdater.firmwareFilename = asset.name
							dfuUpdater.firmwareSelected = true
							dfuUpdater.local = false
							DownloadManager.shared.startDownload(url: asset.browser_download_url)
							presentation.wrappedValue.dismiss()
						} label: {
							Text(i.tag_name)
						}

					}
				}

			}
			Spacer()
		}
//		.onAppear(){
//			DownloadManager.shared.getDownloadUrls()
//		}
	}
}
