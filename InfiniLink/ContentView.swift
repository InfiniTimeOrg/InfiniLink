//
//  ContentView.swift
//  InfiniLink
//
//  Created by Liam Emry on 10/2/24.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var remindersManager = RemindersManager.shared
    
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
            remindersManager.requestReminderAccess()
            
            NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { _ in
                remindersManager.fetchAllReminders()
            }
        }
    }
}

#Preview {
    ContentView()
}
