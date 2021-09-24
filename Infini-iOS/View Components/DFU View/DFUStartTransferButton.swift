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
	@Binding var firmwareURL: URL
	
	@EnvironmentObject var dfuUpdater: DFU_Updater
	@ObservedObject var bleManager = BLEManager.shared
	
	var body: some View {
		Button {
			if updateStarted {
				dfuUpdater.stopTransfer()
				updateStarted = false
			} else {
				dfuUpdater.prepare(location: firmwareURL, device: bleManager)
				dfuUpdater.transfer()
				updateStarted = true
			}} label: {
			Text(updateStarted ? "Stop Transfer" : "Start Transfer")
				.padding()
				.padding(.vertical, 7)
				.frame(maxWidth: .infinity, alignment: .center)
				.background(colorScheme == .dark ? (firmwareSelected ? Color.darkGray : Color.darkestGray) : (firmwareSelected ? Color.blue : Color.lightGray))
				.foregroundColor(firmwareSelected ? Color.white : Color.gray)
				.cornerRadius(10)
				.padding(.horizontal, 20)
				.padding(.bottom)
		}.disabled(!firmwareSelected)
	}
}
