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
				Text("\(NSLocalizedString("title", comment: "")): ")
					.padding(.leading)
				Text("Title: ")
					.padding(.horizontal)
				Text("\(NSLocalizedString("title", comment: "")): ")
					.padding(.leading)
				TextField("", text: $notificationTitle)
			}
			Divider()
				.padding(.horizontal)
			TextEditor(text: $notificationBody)
				.padding(.horizontal)
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
		}
	}
}
