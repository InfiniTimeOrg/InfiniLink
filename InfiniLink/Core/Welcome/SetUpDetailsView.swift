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
    @State private var weight = ""
    @State private var height = ""
    
    @FocusState var isWeightFocused: Bool
    @FocusState var isHeightFocused: Bool
    
    let list: Bool
    
    func resetFields() {
        personalizationController.weight = nil
        personalizationController.height = nil
        weight = ""
        height = ""
    }
    func filteredUnit(_ unit: Double) -> String {
        String(unit).replacingOccurrences(of: ".0", with: "")
    }
    
    init(list: Bool = false) {
        self.list = list
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
            Group {
                Section {
                    Picker("Units", selection: $personalizationController.units) {
                        Text("Metric").tag(PersonalizationController.Unit.metric)
                        Text("Imperial").tag(PersonalizationController.Unit.imperial)
                    }
                    .onChange(of: personalizationController.units) { _ in
                        resetFields()
                    }
                }
                Section {
                    Picker("Gender", selection: $personalizationController.gender) {
                        Text("Male").tag(PersonalizationController.Gender.male)
                        Text("Female").tag(PersonalizationController.Gender.female)
                    }
                }
                Section {
                    HStack(spacing: 12) {
                        Text("Weight")
                        TextField("Optional", text: $weight)
                            .focused($isWeightFocused)
                            .keyboardType(.decimalPad)
                            .filterText(input: $weight)
                    }
                    .onTapGesture {
                        isWeightFocused = true
                    }
                } footer: {
                    Text("Your approximate weight, in \(personalizationController.units == .metric ? "kg" : "lbs").")
                }
                Section {
                    HStack(spacing: 12) {
                        Text("Height")
                        TextField("Optional", text: $height)
                            .focused($isHeightFocused)
                            .keyboardType(.decimalPad)
                            .filterText(input: $height)
                    }
                    .onTapGesture {
                        isHeightFocused = true
                    }
                } footer: {
                    Text("Your approximate height, in \(personalizationController.units == .metric ? "cm" : "inches").")
                }
            }
            .keyboardType(.decimalPad)
            if !list {
                Button {
                    nextViewActive = true
                    
                    // We don't need to assign any vars here because it's handled by the onDisappear
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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                // Don't show the button if the user has edited anything
                if !list && weight == filteredUnit(personalizationController.calculatedWeight) && height == filteredUnit(personalizationController.calculatedHeight) {
                    Button("Skip") {
                        nextViewActive = true
                    }
                }
            }
        }
        .onAppear {
            if let weight = personalizationController.weight, weight > 0 {
                self.weight = filteredUnit(personalizationController.calculatedWeight)
            }
            if let height = personalizationController.height, height > 0 {
                self.height = filteredUnit(personalizationController.calculatedHeight)
            }
        }
        .onDisappear {
            if personalizationController.units == .imperial {
                personalizationController.height = (Double(height) ?? 0) * 2.54
                personalizationController.weight = (Double(weight) ?? 0) / 2.205
            } else {
                personalizationController.height = Double(height)
                personalizationController.weight = Double(weight)
            }
        }
    }
}

struct NotificationsSetupView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var personalizationController = PersonalizationController.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    
    @AppStorage("waterReminder") var waterReminder = true
    @AppStorage("remindOnStepGoalCompletion") var remindOnStepGoalCompletion = true
    @AppStorage("heartRangeReminder") var heartRangeReminder = false
    @AppStorage("sendLowBatteryNotification") var sendLowBatteryNotification = true
    
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
                Toggle("Water Reminder", isOn: $waterReminder)
            }
            Section(footer: Text("Get a notification when your heart rate goes above or below the specified range.") + Text(" You can customize this in notification settings.")) {
                Toggle("Heart Range Notifications", isOn: $heartRangeReminder)
            }
            Section(header: Text("Daily Goals"), footer: Text("Get notified when you reach your daily fitness goals.")) {
                Toggle("Steps", isOn: $remindOnStepGoalCompletion)
            }
            Section(header: Text("Battery"), footer: Text("Get notified when your watch's battery is low.")) {
                Toggle("Notify on Low Battery", isOn: $sendLowBatteryNotification)
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

struct FilteredText: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) { newValue in
                let filtered = newValue.filter { "0123456789.".contains($0) }
                
                if filtered != text {
                    //The string contained bad characters
                    text = ""
                    return
                }
                
                text = filtered
            }
    }
}

extension View {
    func filterText(input: Binding<String>) -> some View {
        modifier(FilteredText(text: input))
    }
}

#Preview {
    SetUpDetailsView()
}
