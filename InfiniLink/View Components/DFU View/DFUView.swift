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
                DFUWithoutBLE(title: NSLocalizedString("pinetime_not_available", comment: ""), subtitle: NSLocalizedString("please_check_your_connection_and_try_again", comment: ""))
            }
		} else {
            DFUWithoutBLE(title: NSLocalizedString("bluetooth_not_available", comment: ""), subtitle: NSLocalizedString("please_enable_bluetooth_try_again", comment: ""))
		}
	}
}

#Preview {
    DFUView()
}
