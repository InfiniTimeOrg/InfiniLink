//
//  ArbitraryNotification.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/22/21.
//  
//
    

import Foundation
import SwiftUI

struct ArbitraryNotificationSheet: View {
	@EnvironmentObject var bleManager: BLEManager
	@Environment(\.colorScheme) var colorScheme
	@State var arbitraryNotification: String = ""
	var placeholderString = "enter text here"
	@Namespace var arbitraryNotificationSheet
	
//	init() {
//		UITextView.appearance().backgroundColor = .clear
//	}
	
	var body: some View {
		VStack{
			Text("Enter notification below")
				.font(.title)
				.padding()
			Divider()
			TextEditor(text: $arbitraryNotification)
				.padding(.horizontal)
			Button(action: {
				bleManager.sendNotification(notification: arbitraryNotification)
				SheetManager.shared.showSheet = false
				SheetManager.shared.sheetSelection = .connect
			}) {
				Text("Send Notification")
					.padding()
					.padding(.vertical, 7)
					.frame(maxWidth: .infinity, alignment: .center)
					.background(colorScheme == .dark ? Color.darkGray : Color.gray)
					.foregroundColor(Color.white)
					.cornerRadius(10)
					.padding(.horizontal, 20)
					.padding(.bottom)
			}
		}.navigationTitle(Text("Send Notification"))
	}
}
