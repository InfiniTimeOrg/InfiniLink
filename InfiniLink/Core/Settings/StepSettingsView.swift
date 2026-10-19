//
//  StepSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct StepSettingsView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @StateObject private var editor = WatchSettingsEditor()
    
    var body: some View {
        ConnectedView {
            List {
                if let file = editor.file, !editor.usingDefaults {
                    Section {
                        Stepper(value: Binding(
                            get: { Int(file.stepsGoal) },
                            set: { editor.file?.stepsGoal = UInt32($0) }
                        ), in: 1000...500000, step: 1000) {
                            HStack {
                                Text("Step Goal")
                                Spacer()
                                Text(Int(file.stepsGoal), format: .number)
                                    .foregroundStyle(.gray)
                            }
                        }
                        WatchSettingsSaveButton(editor: editor)
                    }
                } else if editor.usingDefaults {
                    Text("\(deviceManager.name) is using its default settings. Save them in Customization first, then change your step goal.")
                } else if editor.loadFailed {
                    Text("InfiniLink couldn't read the settings from \(deviceManager.name).")
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                if editor.file == nil {
                    editor.load()
                }
            }
        }
        .navigationTitle("Settings")
        .modifier(WatchSettingsAlerts(editor: editor, deviceName: deviceManager.name))
    }
}

#Preview {
    NavigationStack {
        StepSettingsView()
    }
}
