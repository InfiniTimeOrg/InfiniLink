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

    private var time: Binding<Date> {
        Binding(
            get: {
                let file = editor.file ?? WatchAlarmFile.defaults
                return Calendar.current.date(bySettingHour: Int(file.hours), minute: Int(file.minutes), second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                editor.file?.hours = UInt8(components.hour ?? 7)
                editor.file?.minutes = UInt8(components.minute ?? 0)
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
                    Section {
                        Toggle("Enable Alarm", isOn: Binding(
                            get: { file.isEnabled },
                            set: { enabled in withAnimation { editor.file?.isEnabled = enabled } }
                        ))
                    }
                    if file.isEnabled {
                        Section {
                            DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                            Picker("Repeat", selection: Binding(
                                get: { file.recurrence },
                                set: { editor.file?.recurrence = $0 }
                            )) {
                                Text("Never").tag(WatchAlarmFile.Recurrence.none)
                                Text("Every Day").tag(WatchAlarmFile.Recurrence.daily)
                                Text("Weekdays").tag(WatchAlarmFile.Recurrence.weekdays)
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
                } else if editor.loadFailed {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("InfiniLink couldn't read the alarm from \(deviceManager.name).")
                        if let detail = editor.failureDetail {
                            Text(detail)
                                .font(.footnote.monospaced())
                                .foregroundStyle(.gray)
                                .textSelection(.enabled)
                        }
                    }
                } else {
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
