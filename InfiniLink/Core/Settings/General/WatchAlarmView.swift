//
//  WatchAlarmView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct WatchAlarmView: View {
    @ObservedObject var deviceManager = DeviceManager.shared

    @StateObject private var editor = WatchAlarmEditor()

    private func time(_ index: Int, _ alarm: WatchAlarmFile.Alarm) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: Int(alarm.hours), minute: Int(alarm.minutes), second: 0, of: Date()) ?? Date() },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                editor.file?[index]?.hours = UInt8(components.hour ?? 7)
                editor.file?[index]?.minutes = UInt8(components.minute ?? 0)
            }
        )
    }

    var body: some View {
        ConnectedView {
            List {
                if !WatchAlarmFile.supported(onFirmware: deviceManager.firmware) {
                    Text("Setting the alarm from InfiniLink needs InfiniTime 1.15 or later.")
                } else if editor.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let file = editor.file {
                    ForEach(0..<file.count, id: \.self) { index in // Ignore any alarms we can't read
                        if let alarm = file[index] {
                            Section {
                                Toggle("Enable Alarm", isOn: Binding(
                                    get: { alarm.isEnabled },
                                    set: { enabled in withAnimation { editor.file?[index]?.isEnabled = enabled } }
                                ))
                                if alarm.isEnabled {
                                    DatePicker("Time", selection: time(index, alarm), displayedComponents: .hourAndMinute)
                                    Picker("Repeat", selection: Binding(
                                        get: { alarm.recurrence },
                                        set: { editor.file?[index]?.recurrence = $0 }
                                    )) {
                                        Text("Never").tag(WatchAlarmFile.Recurrence.none)
                                        Text("Every Day").tag(WatchAlarmFile.Recurrence.daily)
                                        Text("Weekdays").tag(WatchAlarmFile.Recurrence.weekdays)
                                    }
                                }
                            } header: {
                                if file.count > 1 {
                                    Text("Alarm \(index + 1)")
                                }
                            }
                        }
                    }
                    Section {
                        Button {
                            editor.showSaveConfirmation = true
                        } label: {
                            HStack {
                                Text("Save to Watch")
                                if editor.isSaving {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(!editor.hasChanges || editor.isSaving)
                    }
                } else if !editor.loadFailed {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                if editor.file == nil && WatchAlarmFile.supported(onFirmware: deviceManager.firmware) {
                    editor.load()
                }
            }
        }
        .navigationTitle("Alarm")
        .alert("Save to \(deviceManager.name)?", isPresented: $editor.showSaveConfirmation) {
            Button("Save") {
                editor.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your watch only loads the alarm when it starts, so it applies after you restart it by pressing and holding the side button. Changing the alarm on the watch before then will undo this.")
        }
        .alert("Couldn't Save Alarm", isPresented: $editor.showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Make sure your watch is connected and try again.")
        }
    }
}

#Preview {
    NavigationStack {
        WatchAlarmView()
    }
}
