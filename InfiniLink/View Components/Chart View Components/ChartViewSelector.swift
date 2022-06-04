//
//  ChartViewSelector.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/28/21.
//  
//
    

import Foundation
import SwiftUI

struct CurrentChart: View {
	@ObservedObject var chartManager = ChartManager.shared
	
	var body: some View {
        Text("None")
		//switch chartManager.currentChart {
		//case .heart:
		//	HeartChart()
		//case .battery:
		//	BatteryChart()
		//}
	}
}
