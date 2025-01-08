//
//  SetUpDetailsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct SetUpDetailsView: View {
    @ObservedObject var personalizationController = PersonalizationController.shared
    
    @State private var isNavActive: Bool = false
    
    @FocusState var isBirthyearFocused: Bool
    @FocusState var isWeightFocused: Bool
    @FocusState var isHeightFocused: Bool

    @ObservedObject var weight = NumbersOnly()
    
    let list: Bool
    
    init(list: Bool = false) {
        self.list = list
    }
    
    var body: some View {
        if list {
            content
        } else {
            NavigationView {
                content
            }
            .navigationViewStyle(.stack)
        }
    }
    
    var content: some View {
        Form {
            if !list {
                VStack(alignment: .center, spacing: 8) {
                    // We can't use the nav link as the button because a chevron appears when inside a List/Form
                    NavigationLink("", isActive: $isNavActive, destination: { NotificationsSetupView() })
                        .hidden()
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 60).weight(.medium))
                        .foregroundStyle(.blue)
                    Text("Let's get you set up.")
                        .font(.largeTitle.weight(.bold))
                    Text("To accurately measure calories and distance, you'll need to enter some basic details.")
                        .foregroundStyle(.gray)
                }
                .multilineTextAlignment(.center)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
            Group {
                Section {
                    HStack(spacing: 12) {
                        Text("Birth Year")
                        TextField("Optional", text: .constant(""))
                            .focused($isBirthyearFocused)
                    }
                    .onTapGesture {
                        isBirthyearFocused = true
                    }
                }
                Section {
                    // We need a better way to get this data
                    HStack(spacing: 12) {
                        Text("Weight")
                        TextField("Optional", text: $weight.value)
                            .focused($isWeightFocused)
                    }
                    .onTapGesture {
                        isWeightFocused = true
                    }
                } footer: {
                    Text("Your approximate weight, in lbs.")
                }
                Section {
                    // We need a better way to get this data
                    HStack(spacing: 12) {
                        Text("Height")
                        TextField("Optional", text: .constant(""))
                            .focused($isHeightFocused)
                    }
                    .onTapGesture {
                        isHeightFocused = true
                    }
                } footer: {
                    Text("Your approximate height, in inches.")
                }
            }
            .keyboardType(.decimalPad)
            if !list {
                Button {
                    isNavActive = true
                } label: {
                    Text("Next")
                        .padding()
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(list ? "Health Details" : "")
        .interactiveDismissDisabled()
        .toolbar {
            if !list {
                Button("Skip") {
                    isNavActive = true
                }
            }
        }
    }
}

struct NotificationsSetupView: View {
    @ObservedObject var personalizationController = PersonalizationController.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var remindersManager = RemindersManager.shared
    
    @AppStorage("waterReminder") var waterReminder = true
    @AppStorage("enableReminders") var enableReminders = true
    @AppStorage("enableCalendarNotifications") var enableCalendarNotifications = true
    @AppStorage("remindOnStepGoalCompletion") var remindOnStepGoalCompletion = true
    
    var body: some View {
        Form {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60).weight(.medium))
                    .foregroundStyle(.red)
                Text("Notifications")
                    .font(.largeTitle.weight(.bold))
                Text("Get notifications on your watch when you reach goals, when it's time to drink water, and more.")
                    .foregroundStyle(.gray)
            }
            .multilineTextAlignment(.center)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
            Section("Health") {
                Toggle("Water Reminder", isOn: $waterReminder)
            }
            Section(header: Text("Daily Goals"), footer: Text("Get notified when you reach your daily fitness goals.")) {
                Toggle("Steps", isOn: $remindOnStepGoalCompletion)
            }
            Section(header: Text("Other"), footer: Text("Receive notifications on your watch when reminders and calendar events are due.")) {
                Toggle("Reminder Notifications", isOn: $enableReminders)
                Toggle("Calendar Notifications", isOn: $enableCalendarNotifications)
            }
            Button {
                notificationManager.requestNotificationAuthorization()
                remindersManager.requestAccess()
                
                personalizationController.showSetupSheet = false
            } label: {
                Text("Continue")
                    .padding()
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    SetUpDetailsView()
}
