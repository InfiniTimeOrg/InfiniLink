//
//  DFUFileSelectButton.swift
//  DFUFileSelectButton
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import Foundation
import SwiftUI

struct DFUFileSelectButton: View {
	@Environment(\.colorScheme) var colorScheme
	@Binding var openFile: Bool
	@ObservedObject var bleManager = BLEManager.shared
	@State var actionSheet = false
	
	var body: some View{
		Button(action:{
			actionSheet.toggle()
		}) {
			Text(NSLocalizedString("select_firmware_file", comment: ""))
//				.padding()
//				.padding(.vertical, 7)
//				.frame(maxWidth: .infinity, alignment: .center)
//				.background(colorScheme == .dark ? (bleManager.isConnectedToPinetime ? Color.darkGray : Color.darkestGray) : (bleManager.isConnectedToPinetime ? Color.blue : Color.lightGray))
				.foregroundColor(bleManager.isConnectedToPinetime ? Color.blue : Color.gray)
//				.cornerRadius(10)
//				.padding(.horizontal, 20)
		}.disabled(!bleManager.isConnectedToPinetime)
			.actionSheet(isPresented: $actionSheet) {
				ActionSheet(title: Text(NSLocalizedString("select_file_source", comment: "")), buttons: [
					.default(Text(NSLocalizedString("use_local_file", comment: "")), action: {
						openFile.toggle()
						DFU_Updater.shared.local = true
					}),
					.default(Text(NSLocalizedString("download_firmware_file", comment: "")), action: {
						//DownloadManager.shared.results = []
						SheetManager.shared.sheetSelection = .downloadUpdate
						SheetManager.shared.showSheet = true
						DFU_Updater.shared.local = false
					}),
					.cancel()
						
				])
			}
	}
}
