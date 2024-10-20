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
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var remindersManager = RemindersManager.shared
    @ObservedObject var personalizationController = PersonalizationController.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    
    @AppStorage("caloriesGoal") var caloriesGoal = 400
    @AppStorage("pairedDeviceID") var pairedDeviceID: String?
    @AppStorage("remindOnStepGoalCompletion") var remindOnStepGoalCompletion = true
    @AppStorage("remindOnCaloriesGoalCompletion") var remindOnCaloriesGoalCompletion = true
    
    var body: some View {
        Group {
            if pairedDeviceID != nil {
                // TODO: onChange only works in foreground, so we need to create background tasks
                DeviceView()
                    .onChange(of: bleManager.weatherCharacteristic) { _ in
                        WeatherController.shared.fetchWeatherData()
                    }
                    .onChange(of: bleManager.batteryLevel) { bat in
                        notificationManager.checkToSendLowBatteryNotification()
                    }
                    .onChange(of: bleManager.stepCount) { stepCount in
                        if stepCount == Int(deviceManager.settings.stepsGoal) && remindOnStepGoalCompletion {
                            notificationManager.sendStepGoalReachedNotification()
                        }
                    }
                    .onChange(of: FitnessCalculator.shared.calculateCaloriesBurned(steps: bleManager.stepCount)) { calories in
                        if Int(calories) == caloriesGoal && remindOnCaloriesGoalCompletion {
                            notificationManager.sendCaloriesGoalReachedNotification()
                        }
                    }
                    .sheet(isPresented: $personalizationController.showSetupSheet) {
                        SetUpDetailsView()
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
