//
//  ContentView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    var body: some View {
        Group {
            if bleManager.pairedDeviceID != nil || bleManager.isConnectedToPinetime {
                DeviceView()
            } else {
                WelcomeView()
            }
        }
        .onAppear {
            bleManager.startScanning()
        }
    }
}

#Preview {
    ContentView()
}
