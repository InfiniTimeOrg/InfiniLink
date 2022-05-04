//
//  DFUStartTransferButton.swift
//  DFUStartTransferButton
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import Foundation
import SwiftUI

struct DFUStartTransferButton: View {
	
	@Environment(\.colorScheme) var colorScheme
	@Binding var updateStarted: Bool
	@Binding var firmwareSelected: Bool
	
	@ObservedObject var dfuUpdater = DFU_Updater.shared
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var downloadManager = DownloadManager.shared
	
    //var startDownload: Bool = false
    
	var body: some View {
		Button {
			if updateStarted {
				dfuUpdater.stopTransfer()
				updateStarted = false
				dfuUpdater.firmwareURL = URL(fileURLWithPath: "")
				dfuUpdater.firmwareSelected = false
				dfuUpdater.firmwareFilename = ""
			} else {
				dfuUpdater.percentComplete = 0
				if dfuUpdater.local {
					dfuUpdater.transfer()
					updateStarted = true
				} else {
                    downloadManager.startTransfer = true
                    print(downloadManager.browser_download_url)
                    downloadManager.startDownload(url: downloadManager.browser_download_url)
                    print(downloadManager.downloading)
                    
                    downloadManager.downloading
                    
					updateStarted = true
				}
			}} label: {
				Text(updateStarted ? "Stop Transfer" :
						(dfuUpdater.local ? "Download and Install" :
						(downloadManager.downloading ? "Downloading" : "Download and Install")))
				//.padding()
				//.padding(.vertical, 7)
				//.frame(maxWidth: .infinity, alignment: .center)
				//.background(colorChooser())
				//.foregroundColor(firmwareSelected ? Color.white : (updateStarted ? Color.white : Color.gray))
				//.cornerRadius(10)
				//.padding(.horizontal, 20)
				//.padding(.bottom)
			}.disabled(buttonDisabled())
		
	}
}
