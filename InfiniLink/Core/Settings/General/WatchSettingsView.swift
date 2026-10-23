//
//  WatchSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct WatchSettingsView: View {
    @ObservedObject var deviceManager = DeviceManager.shared

    @StateObject private var editor = WatchSettingsEditor()

    private let timeouts: [UInt32] = [5000, 7000, 10000, 15000, 20000, 30000]
    private let wakeModes: [(LocalizedStringKey, WakeUpMode)] = [
        ("Single Tap", .SingleTap),
        ("Double Tap", .DoubleTap),
        ("Raise Wrist", .RaiseWrist),
        ("Shake", .Shake),
        ("Lower Wrist to Sleep", .LowerWrist)
    ]

    private func binding<T>(_ keyPath: WritableKeyPath<WatchSettingsFile, T>, default value: T) -> Binding<T> {
        Binding(
            get: { editor.file?[keyPath: keyPath] ?? value },
            set: { editor.file?[keyPath: keyPath] = $0 }
        )
    }

    var body: some View {
        ConnectedView {
            List {
                if editor.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let file = editor.file {
                    WatchSettingsDefaultsSection(editor: editor, deviceName: deviceManager.name)
                    Section {
                        NavigationLink {
                            WatchFaceSettingsView(editor: editor)
                        } label: {
                            HStack {
                                Text("Watch Face")
                                Spacer()
                                Text(LocalizedStringKey(WatchFaceCatalog.shared.name(for: file.watchFace)))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    Section("Display") {
                        Picker("Screen Timeout", selection: binding(\.screenTimeOut, default: 15000)) {
                            ForEach(timeouts, id: \.self) { timeout in
                                Text(Duration.milliseconds(Int(timeout)).formatted(.units(allowed: [.seconds], width: .wide))).tag(timeout)
                            }
                        }
                        Picker("Brightness", selection: binding(\.brightLevel, default: 3)) {
                            Text("Low").tag(UInt8(2))
                            Text("Medium").tag(UInt8(3))
                            Text("High").tag(UInt8(4))
                        }
                        if file.supportsAlwaysOnDisplay {
                            Toggle("Always On Display", isOn: binding(\.alwaysOnDisplay, default: false))
                        }
                    }
                    Section("Time") {
                        Picker("Time Format", selection: binding(\.clockType, default: 0)) {
                            Text("24-Hour").tag(ClockType.H24.rawValue)
                            Text("12-Hour").tag(ClockType.H12.rawValue)
                        }
                        Picker("Chimes", selection: binding(\.chimesOption, default: 0)) {
                            Text("Off").tag(ChimesOption.None.rawValue)
                            Text("Every Hour").tag(ChimesOption.Hours.rawValue)
                            Text("Every Half Hour").tag(ChimesOption.HalfHours.rawValue)
                        }
                    }
                    Section {
                        ForEach(wakeModes, id: \.1) { mode in
                            Toggle(mode.0, isOn: Binding(
                                get: { file.isWakeUpModeOn(mode.1) },
                                set: { enabled in withAnimation { editor.file?.setWakeUpMode(mode.1, enabled: enabled) } }
                            ))
                        }
                        if file.isWakeUpModeOn(.Shake) {
                            VStack(alignment: .leading) {
                                Text("Shake Sensitivity")
                                Slider(value: Binding(
                                    get: { Double(file.shakeWakeThreshold) },
                                    set: { editor.file?.shakeWakeThreshold = UInt16($0) }
                                ), in: 0...4095) {
                                    Text("Shake Sensitivity")
                                } minimumValueLabel: {
                                    Text("More")
                                } maximumValueLabel: {
                                    Text("Less")
                                }
                            }
                        }
                    } header: {
                        Text("Wake Up")
                    } footer: {
                        Text("Single tap and double tap can't both be on.")
                    }
                    Section {
                        WatchSettingsSaveButton(editor: editor)
                    }
                } else if editor.loadFailed {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("InfiniLink couldn't read the settings from \(deviceManager.name). Watch settings need InfiniTime 1.14 or later.")
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
                if editor.file == nil {
                    editor.load()
                }
            }
        }
        .navigationTitle("Customization")
        // Also handles saves from the watch face screen
        .modifier(WatchSettingsAlerts(editor: editor, deviceName: deviceManager.name))
    }
}

#Preview {
    NavigationStack {
        WatchSettingsView()
    }
}
