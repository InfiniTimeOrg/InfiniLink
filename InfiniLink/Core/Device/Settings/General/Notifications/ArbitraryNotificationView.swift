//
//  ArbitraryNotificationView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/21/24.
//

import SwiftUI

struct ArbitraryNotificationView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var content = ""
    
    @FocusState var isTitleFocused: Bool
    @FocusState var isBodyFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isTitleFocused)
                TextEditor(text: $content)
                    .focused($isBodyFocused)
            }
            .navigationTitle("Send Notification")
            .onAppear {
                isTitleFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        BLEWriteManager().sendNotification(AppNotification(title: title, subtitle: content))
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: bleManager.notifyCharacteristic) { characteristic in
            if characteristic == nil {
                // Dismiss the sheet if we can't send a notification
                dismiss()
            }
        }
    }
}

#Preview {
    ArbitraryNotificationView()
}
