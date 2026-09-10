//
//  SetUpDetailsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct SetUpDetailsView: View {
    @ObservedObject var personalizationController = PersonalizationController.shared

    @State private var nextViewActive = false

    let list: Bool

    init(list: Bool = false) {
        self.list = list
    }

    private var isImperial: Bool {
        personalizationController.units == .imperial
    }

    private var weightSelection: Binding<Int> { // store the weight in kg
        Binding(
            get: {
                if let kg = personalizationController.weight, kg > 0 {
                    return Int((isImperial ? kg * 2.205 : kg).rounded())
                }
                return isImperial ? 155 : 70
            },
            set: { personalizationController.weight = isImperial ? Double($0) / 2.205 : Double($0) }
        )
    }

    private var storedInches: Int { // store the height in cm
        if let cm = personalizationController.height, cm > 0 { return Int((cm / 2.54).rounded()) }
        return 67
    }

    private var heightCMSelection: Binding<Int> {
        Binding(
            get: {
                if let cm = personalizationController.height, cm > 0 { return Int(cm.rounded()) }
                return 170
            },
            set: { personalizationController.height = Double($0) }
        )
    }

    private var heightFeetSelection: Binding<Int> {
        Binding(
            get: { storedInches / 12 },
            set: { personalizationController.height = Double($0 * 12 + storedInches % 12) * 2.54 }
        )
    }

    private var heightInchesSelection: Binding<Int> {
        Binding(
            get: { storedInches % 12 },
            set: { personalizationController.height = Double((storedInches / 12) * 12 + $0) * 2.54 }
        )
    }

    private var ageSelection: Binding<Int> {
        Binding(
            get: { personalizationController.age ?? 25 },
            set: { personalizationController.age = $0 }
        )
    }

    var body: some View {
        if list {
            content
        } else {
            NavigationStack {
                content
            }
        }
    }

    var content: some View {
        Form {
            if !list {
                VStack(alignment: .center, spacing: 8) {
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
            Section {
                Picker("Units", selection: $personalizationController.units) {
                    Text("Metric").tag(PersonalizationController.Unit.metric)
                    Text("Imperial").tag(PersonalizationController.Unit.imperial)
                }
                Picker("Energy", selection: $personalizationController.energyUnit) {
                    Text("Calories").tag(PersonalizationController.EnergyUnit.kilocalorie)
                    Text("Kilojoules").tag(PersonalizationController.EnergyUnit.kilojoule)
                }
            }
            Section {
                Picker("Gender", selection: $personalizationController.gender) {
                    Text("Male").tag(PersonalizationController.Gender.male)
                    Text("Female").tag(PersonalizationController.Gender.female)
                }
            }
            Section("Weight") {
                Picker("Weight", selection: weightSelection) {
                    ForEach((isImperial ? 66...660 : 30...300), id: \.self) { value in
                        Text("\(value) \(isImperial ? "lb" : "kg")").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 120)
            }
            Section("Height") {
                if isImperial {
                    HStack(spacing: 0) {
                        Picker("Feet", selection: heightFeetSelection) {
                            ForEach(3...8, id: \.self) { Text("\($0) ft").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        Picker("Inches", selection: heightInchesSelection) {
                            ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(maxHeight: 120)
                } else {
                    Picker("Height", selection: heightCMSelection) {
                        ForEach(120...220, id: \.self) { Text("\($0) cm").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 120)
                }
            }
            Section("Age") {
                Picker("Age", selection: ageSelection) {
                    ForEach(13...100, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 120)
            }
            if !list {
                Button {
                    nextViewActive = true
                } label: {
                    Text("Next")
                        .padding()
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 15))
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(list ? "Health Details" : "")
        .navigationDestination(isPresented: $nextViewActive) {
            NotificationsSetupView()
        }
        .interactiveDismissDisabled()
    }
}

struct NotificationsSetupView: View {
    @ObservedObject var personalizationController = PersonalizationController.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var settingsManager = NotificationSettingsManager.shared

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
            Section(header: Text("Health"), footer: Text("Receive a reminder to drink water for the set amount of times a day.") + Text(" You can customize this in notification settings.")) {
                Toggle("Water Reminder", isOn: $settingsManager.settings.waterReminderEnabled)
            }
            Section(footer: Text("Get a notification when your heart rate goes above or below the specified range.") + Text(" You can customize this in notification settings.")) {
                Toggle("Heart Range Notifications", isOn: $settingsManager.settings.heartSettings.rangeReminderEnabled)
            }
            Section(header: Text("Daily Goals"), footer: Text("Get notified when you reach your daily fitness goals.")) {
                Toggle("Steps", isOn: $settingsManager.settings.goalSettings.stepReminderEnabled)
            }
            Button {
                notificationManager.requestNotificationAuthorization()

                personalizationController.showSetupSheet = false
            } label: {
                Text("Continue")
                    .padding()
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    SetUpDetailsView()
}
