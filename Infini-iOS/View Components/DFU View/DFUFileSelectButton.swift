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
	
	var body: some View{
		Button(action:{
			openFile = true
		}) {
			Text("Select Firmware File")
				.padding()
				.padding(.vertical, 7)
				.frame(maxWidth: .infinity, alignment: .center)
				.background(colorScheme == .dark ? (bleManager.isConnectedToPinetime ? Color.darkGray : Color.darkestGray) : (bleManager.isConnectedToPinetime ? Color.gray : Color.lightGray))
				.foregroundColor(bleManager.isConnectedToPinetime ? Color.white : Color.gray)
				.cornerRadius(10)
				.padding(.horizontal, 20)
		}.disabled(!bleManager.isConnectedToPinetime)
	}
}
