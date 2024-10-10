//
//  ContentView.swift
//  InfiniLink
//
//  Created by Liam Emry on 10/2/24.
//
// TODO: add user settings view to get weight, height, and age to get distance and kcal
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    var body: some View {
        Group {
            if bleManager.pairedDeviceID != nil || bleManager.isConnectedToPinetime {
                DeviceView()
                    .onChange(of: bleManager.batteryLevel) { bat in
                        NotificationManager.shared.checkToSendLowBatteryNotification()
                    }
                    .sheet(isPresented: PersonalizationController.shared.$showSetupSheet) {
                        UserDataCollectionView()
                    }
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
