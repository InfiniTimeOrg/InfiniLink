//
//  RenameDeviceHeader.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/3/21.
//  
//
    

import SwiftUI

struct RenameDeviceHeader: View {
	@ObservedObject var bleManager = BLEManager.shared
	@Binding var renamingDevice: Bool
	@Binding var fieldText: String
	
	var body: some View {
		HStack{
			Text(NSLocalizedString("device_name", comment: ""))
			Spacer()
			Button{
				fieldText = ""
				renamingDevice = true
			} label: {
				Image(systemName: "square.and.pencil")
				Text(NSLocalizedString("rename", comment: ""))
			}
			.disabled(!bleManager.isConnectedToPinetime)
		}
	}
}
