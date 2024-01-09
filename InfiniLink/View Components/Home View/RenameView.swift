//
//  RenamedView.swift
//  InfiniLink
//
//  Created by John Stanley on 11/16/21.
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
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                Text(NSLocalizedString("rename", comment: ""))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    nameManager.updateName(deviceUUID: bleManager.infiniTime.identifier.uuidString, name: changedName)
                    changedName = ""
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(NSLocalizedString("rename", comment: ""))
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.white)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .foregroundColor(.primary)
                }
                .disabled(changedName == deviceInfo.deviceName)
                .opacity(changedName == deviceInfo.deviceName ? 0.5 : 1.0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            VStack {
                TextField("InfiniTime", text: $changedName)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    RenameView()
}
