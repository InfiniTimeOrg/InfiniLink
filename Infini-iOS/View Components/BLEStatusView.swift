//
//  BLEStatusView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/13/21.
//

import Foundation
import SwiftUI

struct StatusView: View {
	
	@EnvironmentObject var bleManager: BLEManager
	@EnvironmentObject var sheetManager: SheetManager
	@Environment(\.colorScheme) var colorScheme
	
	var body: some View {
		VStack (spacing: 10){
			Text("Current Stats")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			
			Spacer()
			if bleManager.isConnectedToPinetime {
				StatusTabs().environmentObject(bleManager)

				Button(action: {
					self.bleManager.disconnect()
				}) {
					Text("Disconnect from PineTime")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(colorScheme == .dark ? Color.darkGray : Color.gray)
						.foregroundColor(Color.white)
						.cornerRadius(10)
						.padding(.horizontal, 20)
						.padding(.bottom)
				}
			} else {
				Button(action: {
					sheetManager.showSheet = true
				}) {
					Text("Connect to PineTime")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(colorScheme == .dark ? Color.darkGray : Color.gray)
						.foregroundColor(Color.white)
						.cornerRadius(10)
						.padding(.horizontal, 20)
						.padding(.bottom)
				}
			}
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
