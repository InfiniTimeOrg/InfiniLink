//
//  ScanningPopover.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/2/21.
//  
//
    

import SwiftUI

struct ScanningPopover: View {
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var deviceInfo = BLEDeviceInfo.shared
	@Environment(\.colorScheme) var colorScheme
	@Binding var show: Bool
		
	var body: some View {
		VStack {
			Spacer()
			if bleManager.isConnectedToPinetime {
				Text("\(NSLocalizedString("connected_to", comment: "")) \(DeviceNameManager().getName(deviceUUID: bleManager.infiniTime.identifier.uuidString).isEmpty ? "InfiniTime" : DeviceNameManager().getName(deviceUUID: bleManager.infiniTime.identifier.uuidString))")
					.padding()
					.frame(maxWidth: .infinity, alignment: .center)
					.background(colorScheme == .dark ? Color.darkGray : Color.lightGray)
					.foregroundColor(Color.white)
					.cornerRadius(10)
					.padding(.horizontal, 20)
					.onAppear {
						DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
							withAnimation() {
								show = false
							}
						}
					}
			} else if bleManager.isScanning {
				Text(NSLocalizedString("scanning", comment: ""))
					.padding()
					.frame(maxWidth: .infinity, alignment: .center)
					.background(colorScheme == .dark ? Color.darkGray : Color.lightGray)
					.foregroundColor(Color.white)
					.cornerRadius(10)
					.padding(.horizontal, 20)
			}
		}
	}
}
