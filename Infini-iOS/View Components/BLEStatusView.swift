//
//  BLEStatusView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/13/21.
//

import Foundation
import SwiftUI

struct StatusView: View {
	
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	
	var body: some View {
		VStack {
			Text("Charts")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			TimeRangeTabs()
			StatusTabs().environmentObject(bleManager)
		}
	}
}

struct StatusView_Previews: PreviewProvider {
	static var previews: some View {
		StatusView()
			.environmentObject(PageSwitcher())
			.environmentObject(BLEManager())
	}
}
