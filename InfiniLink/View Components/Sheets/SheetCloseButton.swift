//
//  SheetCloseButton.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/24/21.
//  
//
    

import SwiftUI

struct SheetCloseButton: View {
	@Environment(\.colorScheme) var colorScheme
	
	var body: some View {
		ZStack (alignment: .top){
			Capsule()
				.frame(width: 40, height: 5, alignment: .top)
				.foregroundColor(colorScheme == .dark ? Color.darkGray : Color.lightGray)
				.padding(.horizontal)
				.padding(.top, 5)
				.ignoresSafeArea()
			HStack () {
				Button {
					SheetManager.shared.showSheet = false
				} label: {
					Text(NSLocalizedString("close", comment: ""))
						.frame(maxWidth: .infinity, alignment: .leading)
						.font(.title2)
						.padding()
				}
				Spacer()
			}
		}
	}
}
