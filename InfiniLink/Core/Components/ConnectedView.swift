//
//  ConnectedView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/19/26.
//

import SwiftUI

struct ConnectedView<Content: View>: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared

    let isReady: Bool?
    let content: () -> Content

    // Defaults to needing the watch's file system, which the settings screens use
    init(isReady: Bool? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.isReady = isReady
        self.content = content
    }

    private var subtitle: String {
        if !bleManager.isBluetoothOn {
            return NSLocalizedString("Turn on Bluetooth to connect to your watch.", comment: "")
        } else if bleManager.isBusy {
            return String(format: NSLocalizedString("InfiniLink will connect to %@ when it's nearby. This will load once it connects.", comment: ""), deviceManager.name)
        }
        return String(format: NSLocalizedString("Connect %@ in General to use this.", comment: ""), deviceManager.name)
    }

    var body: some View {
        if isReady ?? (bleManager.hasLoadedCharacteristics && bleManager.blefsTransfer != nil) {
            content()
        } else if bleManager.isConnectedToPinetime {
            // Connected, still discovering characteristics
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ActionView(Action(
                title: "Your watch isn't connected.",
                subtitle: subtitle,
                icon: "antenna.radiowaves.left.and.right.slash",
                accent: .blue
            ))
        }
    }
}

#Preview {
    ConnectedView {
        Text("Connected")
    }
}
