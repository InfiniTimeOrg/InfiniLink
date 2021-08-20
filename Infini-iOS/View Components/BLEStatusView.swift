//
//  BLEStatusView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/13/21.
//

import Foundation
import SwiftUI

struct StatusView: View {
	
	@EnvironmentObject var bleManager: BLEManager
	
	var body: some View {
		VStack (spacing: 10){
			Text("InfiniTime Status")
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
						.background(Color.gray)
						.foregroundColor(Color.white)
						.cornerRadius(10)
						.padding(.horizontal, 20)
						.padding(.bottom)
				}
			} else {
				Text("Disconnected")
					.padding()
					.padding(.vertical, 7)
					.frame(maxWidth: .infinity, alignment: .center)
					.background(Color.darkGray)
					.foregroundColor(Color.gray)
					.cornerRadius(10)
					.padding(.horizontal, 20)
					.padding(.bottom)
			}
		}//.padding()
	}
}

struct StatusView_Previews: PreviewProvider {
	static var previews: some View {
		StatusView()
			.environmentObject(PageSwitcher())
			.environmentObject(BLEManager())
	}
}
