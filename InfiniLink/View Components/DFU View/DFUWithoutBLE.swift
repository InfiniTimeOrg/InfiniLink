//
//  DFUWithoutBLE.swift
//  DFUWithoutBLE
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import Foundation
import SwiftUI

struct DFUWithoutBLE: View {
	var body: some View{
		VStack {
			Text(NSLocalizedString("bluetooth_not_available", comment: ""))
				.font(.largeTitle)
			Text(NSLocalizedString("please_enable_bluetooth_try_again", comment: ""))
				.font(.title)
		}
	}
}
