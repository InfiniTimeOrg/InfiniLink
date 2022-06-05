//
//  BLEView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import SwiftUI

struct Connect: View {
	
    @ObservedObject var bleManager = BLEManager.shared
	@Environment(\.presentationMode) var presentation
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	
	var body: some View {
		SheetCloseButton()
		VStack (){
			if bleManager.isSwitchedOn {
				Text(NSLocalizedString("available_devices", comment: ""))
					.font(.largeTitle)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
					.onAppear {
						bleManager.startScanning()
					}
			} else {
				Text(NSLocalizedString("available_devices", comment: ""))
					.font(.largeTitle)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
				Text(NSLocalizedString("waiting_for_bluetooth", comment: ""))
					.font(.title)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			List(bleManager.newPeripherals, id: \.identifier.uuidString) { i in
				let deviceName = DeviceNameManager.init().getName(deviceUUID: i.identifier.uuidString)
				Button {
					bleManager.connect(peripheral: i)
					presentation.wrappedValue.dismiss()
				} label: {
					if deviceName == "" {
						Text(i.name ?? NSLocalizedString("unnamed", comment: ""))
					} else {
						Text(deviceName)
					}
				}
			}
			
			Spacer()
		}.onDisappear {
			if bleManager.isScanning {
				bleManager.stopScanning()
			}
		}
	}
}

struct ConnectView_Previews: PreviewProvider {
	static var previews: some View {
		Connect()
	}
}
