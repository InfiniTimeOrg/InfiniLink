//
//  DFUView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import SwiftUI

struct DFUView: View {
	
	@ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var uptimeManager = UptimeManager.shared
	
	var body: some View {
        if bleManager.isSwitchedOn {
            if uptimeManager.connectTime != nil {
                DFUWithBLE()
            } else {
                DFUWithoutConnection()
            }
		} else {
			DFUWithoutBLE()
		}
	}
}

struct DFUView_Previews: PreviewProvider {
	static var previews: some View {
		DFUView()
	}
}
