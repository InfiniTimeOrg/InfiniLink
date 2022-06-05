//
//  MainView.swift
//  MainView
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import Foundation
import SwiftUI

struct MainView: View {

	@ObservedObject var bleManager = BLEManager.shared
	@State var showScanView: Bool = false
	
	
	var body: some View {
		ZStack {
			if showScanView && !BLEAutoconnectManager.shared.shouldDisplayConnectSheet() {
				withAnimation {
					ScanningPopover(show: $showScanView)
						.zIndex(20)
						.transition(.move(edge: .bottom))
						.animation(.spring())
						.padding(.bottom, 20)
				}
			}

		}
		.onChange(of: bleManager.isScanning) { _ in
			if bleManager.isScanning {
				withAnimation() {
					showScanView = true
				}
			}
		}
	}
}
