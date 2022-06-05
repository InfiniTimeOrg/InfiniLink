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
                .foregroundColor(.gray)
			Text(NSLocalizedString("please_enable_bluetooth_try_again", comment: ""))
                .foregroundColor(.gray)
				.font(.caption)
		}
	}
}

struct DFUWithoutConnection: View {
    var body: some View{
        VStack {
            Text(NSLocalizedString("pinetime_not_available", comment: ""))
                .foregroundColor(.gray)
            Text(NSLocalizedString("please_check_your_connection_and_try_again", comment: ""))
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}
