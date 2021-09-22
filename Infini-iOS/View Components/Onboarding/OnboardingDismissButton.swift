//
//  OnboardingDismissButton.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import SwiftUI

struct OnboardingDismissButton: View {
	//@EnvironmentObject var sheetManager: SheetManager
	@Environment(\.colorScheme) var colorScheme
	
	var body: some View{
		Button(action: {
			SheetManager.shared.showSheet = false
		}) {
			Text("Dismiss")
				.padding()
				.padding(.vertical, 7)
				.frame(maxWidth: .infinity, alignment: .center)
				.background(colorScheme == .dark ? Color.darkGray : Color.lightGray)
				.foregroundColor(Color.white)
				.cornerRadius(10)
				.padding(.horizontal, 20)
				.padding(.bottom)
		}
	}
}
