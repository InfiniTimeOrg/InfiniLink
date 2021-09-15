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
			Text("Bluetooth Not Available")
				.font(.largeTitle)
			Text("Please enable Bluetooth and try again.")
				.font(.title)
		}
	}
}
