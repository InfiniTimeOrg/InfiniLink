//
//  DFUProgressBar.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/19/21.
//  
//
    

import Foundation
import SwiftUI

struct DFUProgressBar: View {
	
	@Environment(\.colorScheme) var colorScheme
	@EnvironmentObject var dfuUpdater: DFU_Updater
	
	var body: some View {
		VStack {
			Text("DFU Status: " + dfuUpdater.dfuState)
			Text("Progress:")
			ZStack {
				GeometryReader { geometry in
					Capsule()
						.frame(width: geometry.size.width * 0.9, height: 10, alignment: .center)
						.foregroundColor(colorScheme == .dark ? Color.darkGray : Color.gray)
						.padding(.horizontal)
					Capsule()
						.frame(width: (geometry.size.width * CGFloat((dfuUpdater.percentComplete)/100)) * 0.9, height: 10)
						.foregroundColor(colorScheme == .dark ? Color.white : Color.black)
						.padding(.horizontal)
						.animation(.easeIn)
				}
			}
		}
	}
}

struct DFUProgressBar_Previews: PreviewProvider {
	static var previews: some View {
		DFUProgressBar()
			.environmentObject(PageSwitcher())
			.environmentObject(DFU_Updater())
	}
}
