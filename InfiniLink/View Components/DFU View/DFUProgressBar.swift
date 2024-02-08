//
//  DFUProgressBar.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/19/21.
//  
//
    

import Foundation
import SwiftUI

struct DFUProgressBar: View {
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var ble_fs = BLEFSHandler.shared
	
	var body: some View {
		VStack {
            if DownloadManager.shared.externalResources {
                ProgressView(value: Double(ble_fs.progress), total: Double(ble_fs.externalResourcesSize))
                    .font(.system(size: 16))
            } else {
                ProgressView(dfuUpdater.dfuState, value: dfuUpdater.percentComplete, total: Double(100))
                    .font(.system(size: 16))
            }
		}
	}
}

struct DFUProgressBar_Previews: PreviewProvider {
	static var previews: some View {
		DFUProgressBar()
	}
}
