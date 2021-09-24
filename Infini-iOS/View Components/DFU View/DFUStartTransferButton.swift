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
		if updateStarted {
			Button(action:{
				dfuUpdater.stopTransfer()
				updateStarted = false
			}) {
				Text("Stop Transfer")
					.padding()
					.padding(.vertical, 7)
					.frame(maxWidth: .infinity, alignment: .center)
					.background(colorScheme == .dark ? (firmwareSelected ? Color.darkGray : Color.darkestGray) : (firmwareSelected ? Color.gray : Color.blue))
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
					.background(colorScheme == .dark ? (firmwareSelected ? Color.darkGray : Color.darkestGray) : (firmwareSelected ? Color.gray : Color.blue))
					.foregroundColor(firmwareSelected ? Color.white : Color.gray)
					.cornerRadius(10)
					.padding(.horizontal, 20)
					.padding(.bottom)
			}.disabled(!firmwareSelected)
		}
	}
}
