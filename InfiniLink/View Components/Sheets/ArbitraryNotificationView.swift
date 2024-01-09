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
	var placeholderString = NSLocalizedString("placeholder_text", comment: "")
	
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Send Notification")
                    .font(.title.bold())
                SheetCloseButton()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Divider()
                .padding(.vertical)
                .padding(.horizontal, -16)
            VStack(spacing: 15) {
                HStack {
                    TextField(NSLocalizedString("title", comment: ""), text: $notificationTitle)
                        .padding(12)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
                TextEditor(text: $notificationBody)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2.5)
                    )
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    if !notificationBody.isEmpty || !notificationTitle.isEmpty {
                        BLEWriteManager.init().sendNotification(title: notificationTitle, body: notificationBody)
                    }
                    SheetManager.shared.showSheet = false
                    SheetManager.shared.sheetSelection = .connect
                }) {
                    Text("Send Notification")
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.white)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .disabled(notificationBody.isEmpty && notificationTitle.isEmpty)
                .opacity((notificationBody.isEmpty && notificationTitle.isEmpty) ? 0.5 : 1.0)
            }
        }
        .padding()
    }
}

#Preview {
    ArbitraryNotificationSheet()
}
