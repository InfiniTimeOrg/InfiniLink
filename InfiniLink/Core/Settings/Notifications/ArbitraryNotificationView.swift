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
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                TextEditor(text: $content)
            }
            .navigationTitle("Send Notification")
            .onAppear {
                isFocused = true
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
                // Dismiss the sheet if we disconnect/can't send a notification
                dismiss()
            }
        }
    }
}

#Preview {
    ArbitraryNotificationView()
}
