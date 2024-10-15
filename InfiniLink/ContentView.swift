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
    @ObservedObject var notificationManager = NotificationManager.shared
    
    @AppStorage("caloriesGoal") var caloriesGoal = 400
    
    var body: some View {
        Group {
            if bleManager.pairedDeviceID != nil || bleManager.isConnectedToPinetime {
                DeviceView()
                    .onChange(of: bleManager.batteryLevel) { bat in
                        notificationManager.checkToSendLowBatteryNotification()
                    }
                    .onChange(of: FitnessCalculator.shared.calculateCaloriesBurned(steps: bleManager.stepCount)) { calories in
                        if Int(calories) == caloriesGoal {
                            notificationManager.sendCaloriesGoalReachedNotification()
                        }
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
