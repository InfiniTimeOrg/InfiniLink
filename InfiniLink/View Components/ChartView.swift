//
//  BLEStatusView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/13/21.
//

import Foundation
import SwiftUI

struct ChartView: View {
	
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	
	var body: some View {
		VStack {
			HStack {
				Text(NSLocalizedString("charts", comment: ""))
					.font(.largeTitle)
					.padding(.leading)
					.padding(.vertical)
					.frame(alignment: .leading)
				Button {
					SheetManager.shared.sheetSelection = .chartSettings
					SheetManager.shared.showSheet = true
				} label: {
					Image(systemName: "gear")
						.imageScale(.large)
						.padding(.vertical)
				}
				Spacer()
			}
//			TimeRangeTabs()
			StatusTabs()
			CurrentChart()
		}
	}
}

struct ChartView_Previews: PreviewProvider {
	static var previews: some View {
		ChartView()
			.environmentObject(PageSwitcher())
			.environmentObject(BLEManager())
	}
}
