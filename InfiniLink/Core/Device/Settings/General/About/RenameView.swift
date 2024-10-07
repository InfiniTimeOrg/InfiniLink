//
//  RenameView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct RenameView: View {
    @State var name: String = ""
    
    var body: some View {
        List {
            TextField("InfiniTime", text: $name)
                .submitLabel(.done)
        }
        .navigationTitle("Rename")
        .onAppear {
            name = DeviceInfoManager.shared.deviceName
        }
        .onDisappear {
            DeviceNameManager().setName(deviceUUID: BLEManager.shared.pairedDeviceID!, name: name)
        }
    }
}

#Preview {
    NavigationView {
        RenameView()
    }
}
