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
                        
                        deviceManager.updateName(name: name.trimmingCharacters(in: .whitespaces), for: BLEManager.shared.pairedDevice)
                    }
                if isFocused && !name.isEmpty {
                    Button {
                        name = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10).weight(.semibold))
                            .foregroundStyle(.gray)
                            .padding(5)
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

#Preview {
    NavigationView {
        RenameView()
    }
}
