//
//  BLEManagerExtensions.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/15/21.
//  
//
    

import Foundation
import CoreBluetooth
import SwiftUICharts

extension BLEManager {
	
	// this function converts string to ascii and writes to the selected characteristic. Used for notifications and music app
	func writeASCIIToPineTime(message: String, characteristic: CBCharacteristic) -> Void {
		guard let writeData = message.data(using: .ascii) else {
			if characteristic == musicChars.artist || characteristic == musicChars.track {
				// TODO: for music app, this sends an empty string to not display anything if this is non-ascii. This string can be changed to a "cannot display song title" or whatever but that seems a lot more annoying than just displaying nothing.
				infiniTime.writeValue("".data(using: .ascii)!, for: characteristic, type: .withResponse)
			}
			return
		}
		infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
	}
	
	
	// function to translate heart rate to decimal, copied straight up from this tut: https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor#toc-anchor-014
	func heartRate(from characteristic: CBCharacteristic) -> Int {
		guard let characteristicData = characteristic.value else { return -1 }
		let byteArray = [UInt8](characteristicData)

		let firstBitValue = byteArray[0] & 0x01
		if firstBitValue == 0 {
			// Heart Rate Value Format is in the 2nd byte
			return Int(byteArray[1])
		} else {
			// Heart Rate Value Format is in the 2nd and 3rd bytes
			return (Int(byteArray[1]) << 8) + Int(byteArray[2])
		}
	}
	
	func updateChartInfo(data: Double, heart: Bool) -> LineChartDataPoint {
		let dateFormat = DateFormatter()
		dateFormat.dateFormat = "H:mm:ss"
		return LineChartDataPoint(value: data, xAxisLabel: "Time", description: dateFormat.string(from: Date()), date: Date())
	}
}
