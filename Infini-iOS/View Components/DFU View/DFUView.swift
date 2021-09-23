//
//  DFUView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import SwiftUI

struct DFUView: View {
	
	@ObservedObject var bleManager = BLEManager.shared

	
	var body: some View {
		if bleManager.isSwitchedOn {
			DFUWithBLE().environmentObject(bleManager)
		} else {
			DFUWithoutBLE()
		}
	}
}

struct DFUView_Previews: PreviewProvider {
	static var previews: some View {
		DFUView()
			.environmentObject(BLEManager())
			.environmentObject(DFU_Updater())
	}
}
