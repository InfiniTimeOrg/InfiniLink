//
//  RenamedView.swift
//  InfiniLink
//
//  Created by Micah Stanley on 11/16/21.
//

import SwiftUI

struct RenameView: View {
    
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var changedName: String = BLEDeviceInfo.shared.deviceName
    private var nameManager = DeviceNameManager()
    
    var body: some View {
        return VStack {
            List() {
                AutoFocusTextField("InfiniTime", text: $changedName, onCommit: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    nameManager.updateName(deviceUUID: bleManager.infiniTime.identifier.uuidString, name: changedName)
                    changedName = ""
                    presentationMode.wrappedValue.dismiss()
                })
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitle(Text("Name").font(.subheadline), displayMode: .inline)
        
    }
}

struct AutoFocusTextField: UIViewRepresentable {
    private let placeholder: String
    @Binding private var text: String
    private let onEditingChanged: ((_ focused: Bool) -> Void)?
    private let onCommit: (() -> Void)?
    
    init(_ placeholder: String, text: Binding<String>, onEditingChanged: ((_ focused: Bool) -> Void)? = nil, onCommit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        _text = text
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<AutoFocusTextField>) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.returnKeyType = .done
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context:
                        UIViewRepresentableContext<AutoFocusTextField>) {
        uiView.text = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // needed for modal view to show completely before aufo-focus to avoid crashes
            if uiView.window != nil, !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AutoFocusTextField
        
        init(_ autoFocusTextField: AutoFocusTextField) {
            self.parent = autoFocusTextField
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEditingChanged?(false)
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditingChanged?(true)
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onCommit?()
            return true
        }
    }
}
