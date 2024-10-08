//
//  RenameView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//
// NOTE: we're not using Core Data yet because we are getting errors: Failed to get or decode unavailable reasons and Can't find or decode reasons
//

import SwiftUI

struct RenameView: View {
    @Environment(\.dismiss) var dismiss
    
//    @State var name: String = DeviceInfoManager.shared.deviceName
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        List {
            TextField("InfiniTime", text: DeviceInfoManager.shared.$deviceName)
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit {
                    dismiss()
//                    DeviceNameManager().setName(deviceUUID: BLEManager.shared.pairedDeviceID!, name: name)
                }
        }
        .navigationTitle("Rename")
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    NavigationView {
        RenameView()
    }
}
