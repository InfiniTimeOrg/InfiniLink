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
    
    @Binding var name: String
    
    @State private var draft: String
    
    @FocusState var isFocused: Bool
    
    init(_ name: Binding<String>) {
        self._name = name
        self._draft = State(initialValue: name.wrappedValue)
    }
    
    var body: some View {
        List {
            HStack {
                TextField("InfiniTime", text: $draft)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit {
                        dismiss()
                    }
                if !draft.isEmpty {
                    Button {
                        draft = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11).weight(.bold))
                            .foregroundStyle(.gray)
                            .padding(6)
                            .glassBackground(in: Circle())
                    }
                }
            }
        }
        .navigationTitle("Name")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .glassButtonStyle(prominent: true)
            }
        }
        .onAppear {
            isFocused = true
        }
        .onDisappear {
            save()
        }
    }
    
    func save() {
        var newName = draft.trimmingCharacters(in: .whitespaces)
        if newName.isEmpty {
            newName = "InfiniTime"
        }
        guard newName != DeviceManager.shared.name else { return }
        
        name = newName
        DeviceManager.shared.updateName(newName)
    }
}
