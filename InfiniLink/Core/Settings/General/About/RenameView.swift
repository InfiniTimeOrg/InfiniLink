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
    @ObservedObject var bleManager = BLEManager.shared
    
    @Binding var name: String
    
    @FocusState var isFocused: Bool
    
    init(_ name: Binding<String>) {
        self._name = name
    }
    
    var body: some View {
        List {
            HStack {
                TextField("InfiniTime", text: $name)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit {
                        dismiss()
                        
                        var name = self.name
                        if name.trimmingCharacters(in: .whitespaces) == "" {
                            name = "InfiniTime"
                        }
                        
                        deviceManager.updateName(name.trimmingCharacters(in: .whitespaces))
                    }
                if !name.isEmpty {
                    Button {
                        name = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11).weight(.bold))
                            .foregroundStyle(.gray)
                            .padding(6)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .navigationTitle("Name")
        .onAppear {
            isFocused = true
        }
    }
}
