//
//  FilesystemView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import SwiftUI

struct FileSystemView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var bleFs = BLEFSHandler.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var transfer = FileTransferManager.shared
    
    @StateObject private var model: FileSystemViewModel
    
    @State private var showUploadSheet = false
    @State private var isImportingBackup = false
    @State private var showNewFolderView = false
    @State private var showBackUpAlert = false
    @State private var showSoftwareUpdate = false
    @State private var newFolderName = ""
    
    @FocusState private var isNewFolderFocused: Bool
    
    private var isBackingUpOrRestoring: Bool {
        transfer.task == .backingUp || transfer.task == .restoring
    }
    
    init(path: String = "/") {
        _model = StateObject(wrappedValue: FileSystemViewModel(path: path))
    }
    
    var body: some View {
        List {
            if model.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(model.entries, id: \.pathNames) { entry in
                    NavigationLink {
                        if entry.isDirectory {
                            FileSystemView(path: model.path(for: entry.pathNames))
                        } else {
                            FileSystemDetailView(path: model.path(for: entry.pathNames))
                        }
                    } label: {
                        Label(entry.pathNames, systemImage: entry.isDirectory ? "folder" : "doc")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            model.delete(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .disabled(isBackingUpOrRestoring)
        .sheet(isPresented: $showNewFolderView) {
            newFolder
        }
        .fileImporter(isPresented: $showUploadSheet, allowedContentTypes: isImportingBackup ? [.zip] : [.data], allowsMultipleSelection: !isImportingBackup) { result in
            do {
                let urls = try result.get()
                if isImportingBackup {
                    if let url = urls.first {
                        model.openBackup(url)
                    }
                } else {
                    model.pendingFiles = urls
                }
            } catch {
                log("Error getting file: \(error.localizedDescription)", caller: "FilesystemView")
            }
        }
        .refreshable {
            if !isBackingUpOrRestoring {
                await model.refresh()
            }
        }
        .onAppear {
            model.load()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Group {
                    if model.path == "/" {
                        Button {
                            showBackUpAlert = true
                        } label: {
                            Label("Back Up Watch", systemImage: "externaldrive.badge.timemachine")
                        }
                    }
                    Menu {
                        Button {
                            showNewFolderView = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Button {
                            isImportingBackup = false
                            showUploadSheet = true
                        } label: {
                            Label("Upload Files", systemImage: "plus")
                        }
                        if model.path == "/" {
                            Divider()
                            Button {
                                isImportingBackup = true
                                showUploadSheet = true
                            } label: {
                                Label("Restore from Backup", systemImage: "clock.arrow.circlepath")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                .disabled(!bleManager.hasLoadedCharacteristics || model.isLoading || transfer.task != nil)
            }
            if transfer.task != nil {
                StatusToolbarItem {
                    HStack(spacing: 6) {
                        ProgressView()
                        Text("\(transfer.statusText)... ") + Text(transfer.fractionComplete(bytesWritten: bleFs.progress), format: .percent.precision(.fractionLength(0)))
                    }
                    .foregroundStyle(.gray)
                }
            } else if !model.pendingFiles.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    Button("Upload ^[\(model.pendingFiles.count) File](inflect: true)") {
                        model.uploadPendingFiles()
                    }
                }
            }
        }
        .onChange(of: transfer.task == nil) { isDone in
            if isDone {
                model.load()
            }
        }
        .sheet(isPresented: Binding(get: { model.path == "/" && transfer.backupURL != nil }, set: { if !$0 { transfer.backupURL = nil } })) {
            if let url = transfer.backupURL {
                ShareSheet(items: [url])
                    .ignoresSafeArea()
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Restore Backup?", isPresented: Binding(get: { model.pendingRestore != nil }, set: { if !$0 { model.pendingRestore = nil } }), presenting: model.pendingRestore) { contents in
            Button("Restore") {
                model.restore(contents)
            }
            Button("Cancel", role: .cancel) {}
        } message: { contents in
            if contents.manifest.firmware == deviceManager.firmware {
                Text("Files in this backup will replace ones with the same name on \(deviceManager.name).")
            } else {
                Text("This backup is from InfiniTime \(contents.manifest.firmware), but \(deviceManager.name) is on \(deviceManager.firmware). Resources like fonts and images won't be restored.")
            }
        }
        .alert("Backup Restored", isPresented: Binding(get: { model.path == "/" && transfer.restoreResult != nil }, set: { if !$0 { transfer.restoreResult = nil } }), presenting: transfer.restoreResult) { result in
            if result.skippedResources {
                Button("Update Resources") {
                    showSoftwareUpdate = true
                }
            }
            Button("OK", role: .cancel) {}
        } message: { result in
            Text(restoreMessage(result))
        }
        .navigationDestination(isPresented: $showSoftwareUpdate) {
            SoftwareUpdateView()
        }
        .alert("Back Up Watch?", isPresented: $showBackUpAlert) {
            Button("Back Up") {
                transfer.backUp()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This copies the files on \(deviceManager.name) into a backup you can save. You can restore it later from the + menu.")
        }
        .alert("Couldn't Back Up Watch", isPresented: Binding(get: { model.path == "/" && transfer.showBackupError }, set: { transfer.showBackupError = $0 })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Make sure your watch is connected and try again.")
        }
        .alert("Couldn't Open Backup", isPresented: $model.showOpenBackupError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This file isn't an InfiniLink watch backup.")
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(model.path == "/" ? NSLocalizedString("File System", comment: "") : (model.path as NSString).lastPathComponent)
    }
    
    private func restoreMessage(_ result: WatchBackup.RestoreResult) -> String {
        var lines = [String]()
        if result.failed > 0 {
            lines.append(String(format: NSLocalizedString("%d files couldn't be restored.", comment: ""), result.failed))
        }
        if result.skippedSettings {
            lines.append(NSLocalizedString("Some settings in the backup aren't supported by this version of InfiniTime, so they weren't restored.", comment: ""))
        }
        if result.skippedResources {
            lines.append(NSLocalizedString("Resources weren't restored. You can install them later via a software update.", comment: ""))
        }
        if result.restoredSettings {
            lines.append(NSLocalizedString("Restart your watch to apply any new settings.", comment: ""))
        }
        return lines.joined(separator: "\n\n")
    }
    
    var newFolder: some View {
        NavigationStack {
            Form {
                Section(footer: Text(newFolderName.contains(".") ? "The folder name cannot contain a period." : "")) {
                    TextField("Title", text: $newFolderName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isNewFolderFocused)
                }
            }
            .navigationTitle("New Folder")
            .onAppear {
                isNewFolderFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showNewFolderView = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        model.createFolder(named: newFolderName)
                        newFolderName = ""
                        showNewFolderView = false
                    }
                    .disabled(newFolderName.contains(".") || newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct StatusToolbarItem<Content: View>: ToolbarContent {
    @ViewBuilder let content: Content
    
    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItem(placement: .bottomBar) {
                content
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .glassEffect()
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .bottomBar) {
                content
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FileSystemView()
    }
}
