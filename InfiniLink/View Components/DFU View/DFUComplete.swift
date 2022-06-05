//
//  DFUComplete.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/29/21.
//  
//
    

import SwiftUI

struct DFUComplete: View {
	
	var body: some View {
		Text(NSLocalizedString("transfer_completed", comment: ""))
			.font(.largeTitle)
			.padding()
			.foregroundColor(Color.white)
			.background(Color.green)
	}
}
