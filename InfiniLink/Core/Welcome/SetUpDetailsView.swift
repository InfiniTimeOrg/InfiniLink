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
    
    @FocusState var isBirthdateFocused: Bool
    @FocusState var isWeightFocused: Bool
    @FocusState var isHeightFocused: Bool
    
    let listOnly: Bool
    
    init(listOnly: Bool = false) {
        self.listOnly = listOnly
    }
    
    var body: some View {
        Form {
            if !listOnly {
                VStack(alignment: .center, spacing: 10) {
                    // We can't use the nav link as the button because a chevron appears when inside a List/Form
                    NavigationLink("", isActive: $isNavActive, destination: { NotificationsSetupView() })
                        .hidden()
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 65).weight(.medium))
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
            Section {
                HStack(spacing: 12) {
                    Text("Birthdate")
                    TextField("Optional", text: .constant(""))
                        .focused($isBirthdateFocused)
                }
                .onTapGesture {
                    isBirthdateFocused = true
                }
                HStack(spacing: 12) {
                    Text("Weight")
                    TextField("Optional", text: .constant(""))
                        .focused($isWeightFocused)
                }
                .onTapGesture {
                    isWeightFocused = true
                }
                HStack(spacing: 12) {
                    Text("Height")
                    TextField("Optional", text: .constant(""))
                        .focused($isHeightFocused)
                }
                .onTapGesture {
                    isHeightFocused = true
                }
            }
            if !listOnly {
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
        .interactiveDismissDisabled()
    }
}

struct NotificationsSetupView: View {
    @ObservedObject var personalizationController = PersonalizationController.shared
    
    @AppStorage("waterReminder") var waterReminder = true
    @AppStorage("enableReminders") var enableReminders = true
    @AppStorage("remindOnStepGoalCompletion") var remindOnStepGoalCompletion = true
    @AppStorage("remindOnCaloriesGoalCompletion") var remindOnCaloriesGoalCompletion = true
    @AppStorage("remindOnExerciseTimeGoalCompletion") var remindOnExerciseTimeGoalCompletion = true
    
    var body: some View {
        Form {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 65).weight(.medium))
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
                Toggle("Calories", isOn: $remindOnCaloriesGoalCompletion)
                Toggle("Exercise Time", isOn: $remindOnExerciseTimeGoalCompletion)
            }
            Section("Other") {
                Toggle("Reminder Notifications", isOn: $enableReminders)
            }
            Button {
                NotificationManager.shared.requestNotificationAuthorization()
                
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
