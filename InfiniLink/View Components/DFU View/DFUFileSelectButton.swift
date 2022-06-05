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
				.foregroundColor(bleManager.isConnectedToPinetime ? Color.blue : Color.gray)
		}.disabled(!bleManager.isConnectedToPinetime)
			.actionSheet(isPresented: $actionSheet) {
				ActionSheet(title: Text("Select a File Source"), buttons: [
					.default(Text("Use Local File"), action: {
						openFile.toggle()
						DFU_Updater.shared.local = true
					}),
					.default(Text(NSLocalizedString("download_firmware_file", comment: "")), action: {
						SheetManager.shared.showSheet = true
						DFU_Updater.shared.local = false
					}),
					.cancel()
						
				])
			}
	}
}
