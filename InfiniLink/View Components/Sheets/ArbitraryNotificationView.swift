//
//  ArbitraryNotification.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/22/21.
//  
//
    

import Foundation
import SwiftUI

struct ArbitraryNotificationSheet: View {
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	@State var notificationTitle: String = ""
	@State var notificationBody: String = ""
	var placeholderString = "enter text here"
	
	var body: some View {
		ZStack {
			SheetCloseButton()
			HStack {
				Spacer()
				Button {
					UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
					if !notificationBody.isEmpty || !notificationTitle.isEmpty {
						BLEWriteManager.init().sendNotification(title: notificationTitle, body: notificationBody)
					}
					SheetManager.shared.showSheet = false
					SheetManager.shared.sheetSelection = .connect
				} label: {
					Text("Send")
						.font(.title2)
				}
				.padding()
				
			}
		}

		VStack{
			Text(NSLocalizedString("send_notification", comment: ""))
				.font(.title)
				.padding()
			Divider()
				.padding(.horizontal)
			HStack {
<<<<<<< HEAD
				Text("\(NSLocalizedString("title", comment: "")): ")
					.padding(.leading)
=======
				Text("Title: ")
					.padding(.horizontal)
>>>>>>> d1c98d0 (Removed some superfluous padding and labels from the step adjustment sheet for better usability on small screens)
				TextField("", text: $notificationTitle)
			}
			Divider()
				.padding(.horizontal)
			TextEditor(text: $notificationBody)
				.padding(.horizontal)
<<<<<<< HEAD
			Button(action: {
				UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
				if !notificationBody.isEmpty || !notificationTitle.isEmpty {
					BLEWriteManager.init().sendNotification(title: notificationTitle, body: notificationBody)
				}
				SheetManager.shared.showSheet = false
				SheetManager.shared.sheetSelection = .connect
			}) {
				Text(NSLocalizedString("send_notification", comment: ""))
					.padding()
					.padding(.vertical, 7)
					.frame(maxWidth: .infinity, alignment: .center)
					.background(colorScheme == .dark ? Color.darkGray : Color.gray)
					.foregroundColor(Color.white)
					.cornerRadius(10)
					.padding(.horizontal, 20)
					.padding(.bottom)
			}
=======
>>>>>>> 7869ee0 (Removed large button from send notification sheet and replaced it with a simple "send" button at the top that matches the "close" button. This should help people with smaller screens and/or accessibility tweaks)
		}
	}
}
