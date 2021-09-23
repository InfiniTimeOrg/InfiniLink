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
