//
//  ContentView.swift
//  InfiniLink
//
//  Created by Liam Emry on 10/2/24.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @ObservedObject private var bleManager = BLEManager.shared
    
    @AppStorage("pairedDeviceID") private var pairedDeviceID: String?
    
    var body: some View {
        Group {
            if pairedDeviceID != nil {
                DeviceView()
            } else {
                WelcomeView()
            }
        }
        .alert(isPresented: $bleManager.showError) {
            Alert(title: Text("Error"), message: Text(bleManager.error), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    ContentView()
}
