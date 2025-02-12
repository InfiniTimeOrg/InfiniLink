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
    @ObservedObject var personalizationController = PersonalizationController.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    
    @AppStorage("pairedDeviceID") var pairedDeviceID: String?
    
    var body: some View {
        Group {
            if pairedDeviceID != nil {
                DeviceView()
                    .onChange(of: bleManager.weatherCharacteristic) { _ in
                        WeatherController.shared.fetchWeatherData()
                    }
                    .onChange(of: bleManager.batteryLevel) { bat in
                        notificationManager.checkToSendLowBatteryNotification()
                    }
                    .sheet(isPresented: $personalizationController.showSetupSheet) {
                        SetUpDetailsView()
                    }
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
