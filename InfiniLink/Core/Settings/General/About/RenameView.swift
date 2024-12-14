//
//  RenameView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//
//

import SwiftUI

struct RenameView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @State var name: String = DeviceManager.shared.name
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        List {
            TextField("InfiniTime", text: $name)
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit {
                    dismiss()
                    
                    var name = self.name
                    if name.trimmingCharacters(in: .whitespaces) == "" {
                        name = "InfiniTime"
                    }
                    
                    deviceManager.updateName(name: name.trimmingCharacters(in: .whitespaces), for: BLEManager.shared.pairedDevice)
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
