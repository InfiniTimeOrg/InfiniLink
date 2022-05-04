//
//  DFUProgressBar.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/19/21.
//  
//
    

import Foundation
import SwiftUI

struct DFUProgressBar: View {
	
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject var dfuUpdater = DFU_Updater.shared
	
	var body: some View {
		VStack {
				ProgressView(dfuUpdater.dfuState, value: dfuUpdater.percentComplete, total: Double(100))
                .font(.system(size: 16))
                //.font(.caption)
					//.padding()
		}
	}
}

struct DFUProgressBar_Previews: PreviewProvider {
	static var previews: some View {
		DFUProgressBar()
	}
}
