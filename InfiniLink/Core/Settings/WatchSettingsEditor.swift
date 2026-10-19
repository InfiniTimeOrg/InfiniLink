//
//  WatchSettingsEditor.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

class WatchSettingsEditor: ObservableObject {
    @Published var file: WatchSettingsFile?
    @Published private(set) var original: WatchSettingsFile?
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var loadFailed = false
    @Published private(set) var failureDetail: String?
    @Published private(set) var usingDefaults = false
    @Published var showSaveConfirmation = false
    @Published var showSaveError = false

    var hasChanges: Bool {
        file?.data != original?.data
    }

    func load() {
        guard BLEManager.shared.blefsTransfer != nil, !isLoading else { return }

        isLoading = true
        BLEFSHandler.shared.readSettingsFile { file, usingDefaults, detail in
            self.isLoading = false
            self.file = file
            self.original = usingDefaults ? nil : file
            self.usingDefaults = usingDefaults
            self.loadFailed = file == nil
            self.failureDetail = detail
        }
    }

    func requestSave() {
        showSaveConfirmation = true
    }

    func save() {
        guard let file, !isSaving else { return }

        isSaving = true
        BLEFSHandler.shared.writeSettingsFile(file) { success in
            self.isSaving = false
            if success {
                self.original = file
                self.usingDefaults = false
            } else {
                self.showSaveError = true
            }
        }
    }
}

struct WatchSettingsAlerts: ViewModifier {
    @ObservedObject var editor: WatchSettingsEditor

    let deviceName: String

    func body(content: Content) -> some View {
        content
            .alert(editor.usingDefaults ? "Replace Watch Settings?" : "Save to \(deviceName)?", isPresented: $editor.showSaveConfirmation) {
                Button(editor.usingDefaults ? "Replace" : "Save", role: editor.usingDefaults ? .destructive : nil) {
                    editor.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if editor.usingDefaults {
                    Text("This writes a new settings file to \(deviceName). Every setting on it, like the step goal, wake modes, and brightness, is set to what InfiniLink shows or InfiniTime's defaults. Changes apply after you restart your watch by pressing and holding the side button.")
                } else {
                    Text("Your watch only loads its settings when it starts, so changes apply after you restart it by pressing and holding the side button. Changing settings on the watch before then will undo these changes.")
                }
            }
            .alert("Couldn't Save Settings", isPresented: $editor.showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Make sure your watch is connected and try again.")
            }
    }
}

struct WatchSettingsSaveButton: View {
    @ObservedObject var editor: WatchSettingsEditor
    
    var body: some View {
        Button {
            editor.requestSave()
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
}

struct WatchSettingsDefaultsSection: View {
    @ObservedObject var editor: WatchSettingsEditor
    
    let deviceName: String
    
    var body: some View {
        if editor.usingDefaults {
            Section {
                Label("\(deviceName)'s saved settings are from an older version of InfiniTime, so it's using its default settings. Saving writes a new settings file.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}

class WatchAlarmEditor: ObservableObject {
    @Published var file: WatchAlarmFile?
    @Published private(set) var original: WatchAlarmFile?
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var loadFailed = false
    @Published private(set) var failureDetail: String?
    @Published var showSaveConfirmation = false
    @Published var showSaveError = false
    
    var hasChanges: Bool {
        file?.data != original?.data
    }
    
    func load() {
        guard BLEManager.shared.blefsTransfer != nil, !isLoading else { return }
        
        isLoading = true
        BLEFSHandler.shared.readAlarmFile { file, usingDefaults, detail in
            self.isLoading = false
            self.file = file
            self.original = usingDefaults ? nil : file
            self.loadFailed = file == nil
            self.failureDetail = detail
        }
    }
    
    func save() {
        guard let file, !isSaving else { return }
        
        isSaving = true
        BLEFSHandler.shared.writeAlarmFile(file) { success in
            self.isSaving = false
            if success {
                self.original = file
            } else {
                self.showSaveError = true
            }
        }
    }
}
