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
				//.font(.title2)
                .foregroundColor(.gray)
			Text("Please enable Bluetooth and try again.")
                .foregroundColor(.gray)
                //.font(.system(size: 15))
				.font(.caption)
		}
        //.navigationBarTitle(Text("Software Update").font(.subheadline), displayMode: .inline)
	}
}
