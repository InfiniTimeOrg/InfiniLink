//
//  NotificationsSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/4/24.
//

import SwiftUI
import EventKit

struct NotificationsSettingsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    
    @AppStorage("allowBatteryNotifications") var allowBatteryNotifications = true
    @AppStorage("waterReminder") var waterReminder = true
    @AppStorage("waterReminderAmount") var waterReminderAmount = 7
    @AppStorage("standUpReminder") var standUpReminder = true
    @AppStorage("heartRangeReminder") var heartRangeReminder = false
    @AppStorage("minHeartRange") var minHeartRange = 40
    @AppStorage("maxHeartRange") var maxHeartRange = 200
    @AppStorage("watchNotifications") var watchNotifications = true
    @AppStorage("transliterationEnabled") var transliterationEnabled = true
    @AppStorage("remindOnStepGoalCompletion") var remindOnStepGoalCompletion = true
    
    @State private var reminderAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var eventAuthStatus = EKEventStore.authorizationStatus(for: .event)
    
    @State private var showSendNotificationSheet = false
    @State private var showFindLostDeviceSheet = false
    
    let bleWriteManager = BLEWriteManager()
    
    func authDenied(_ status: EKAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .fullAccess:
            return false
        case .denied, .notDetermined, .restricted, .writeOnly:
            return true
        @unknown default:
            return true
        }
    }
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Watch Notifications", isOn: $watchNotifications)
            }
            if watchNotifications {
                Section(header: Text("Health"), footer: Text("Receive a reminder to drink water for the set amount of times a day.")) {
                    Toggle("Water Reminder", isOn: $waterReminder)
                    if waterReminder {
                        Picker("Interval", selection: $waterReminderAmount) {
                            ForEach(0..<9, id: \.self) { amount in
                                Text("\(amount + 1) time\(amount == 0 ? "" : "s")")
                            }
                        }
                    }
                }
                /*
                 Section(footer: Text("Have your watch remind you when to stand up if you've been sedentary for too long.")) {
                 Toggle("Stand-up Reminder", isOn: $standUpReminder)
                 }
                 */
                Section(footer: Text("Get a notification when your heart rate goes above or below the specified range.")) {
                    Toggle("Heart Range Notifications", isOn: $heartRangeReminder)
                    if heartRangeReminder {
                        HStack {
                            Text("Minimum")
                            Spacer()
                            Text("\(minHeartRange)")
                            Stepper("\(minHeartRange)", value: $minHeartRange, in: 40...(maxHeartRange - 1), step: 1)
                                .fontWeight(.semibold)
                                .labelsHidden()
                        }
                        HStack {
                            Text("Maximum")
                            Spacer()
                            Text("\(maxHeartRange)")
                            Stepper("\(maxHeartRange)", value: $maxHeartRange, in: (minHeartRange + 1)...220, step: 1)
                                .fontWeight(.semibold)
                                .labelsHidden()
                        }
                    }
                }
                Section(header: Text("Battery"), footer: Text("Send notifications to your devices about your watch's battery status.")) {
                    Toggle("Battery Notifications", isOn: $allowBatteryNotifications)
                        .disabled(!watchNotifications)
                }
                Section(header: Text("Daily Goals"), footer: Text("Get notified when you reach your daily fitness goals.")) {
                    Toggle("Steps", isOn: $remindOnStepGoalCompletion)
                }
                Section {
                    Toggle("Transliterate to ASCII", isOn: $transliterationEnabled)
                } footer: {
                    Text("Convert accented characters to plain text so notifications display correctly.")
                }
                Section {
                    Button("Send Notification") {
                        showSendNotificationSheet = true
                    }
                    .disabled(bleManager.notifyCharacteristic == nil)
                    .sheet(isPresented: $showSendNotificationSheet) {
                        ArbitraryNotificationView()
                    }
                    Button("Find Lost Device") {
                        showFindLostDeviceSheet = true
                    }
                    .sheet(isPresented: $showFindLostDeviceSheet) {
                        FindLostDeviceView()
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .onChange(of: waterReminderAmount) { _ in
            notificationManager.setWaterRemindersPerDay()
        }
    }
}

#Preview {
    NotificationsSettingsView()
}
