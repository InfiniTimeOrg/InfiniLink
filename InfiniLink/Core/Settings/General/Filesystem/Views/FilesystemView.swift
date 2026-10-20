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
    
    @StateObject private var model: FileSystemViewModel
    
    @State private var hasLoaded = false
    @State private var showUploadSheet = false
    @State private var showNewFolderView = false
    @State private var newFolderName = ""
    
    @FocusState private var isNewFolderFocused: Bool
    
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
        .sheet(isPresented: $showNewFolderView) {
            newFolder
        }
        .fileImporter(isPresented: $showUploadSheet, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
            do {
                model.pendingFiles = try result.get()
            } catch {
                log("Error getting file: \(error.localizedDescription)", caller: "FilesystemView")
            }
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                model.load()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showNewFolderView = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    Button {
                        showUploadSheet = true
                    } label: {
                        Label("Upload Files", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!bleManager.hasLoadedCharacteristics || model.isLoading || model.isUploading)
            }
            ToolbarItem(placement: .bottomBar) {
                if model.isUploading {
                    HStack(spacing: 6) {
                        ProgressView()
                        if model.uploadSize > 0 {
                            Text("Uploading... \(Int(Double(bleFs.progress) / Double(model.uploadSize) * 100))%")
                        } else {
                            Text("Uploading...")
                        }
                    }
                    .foregroundStyle(.gray)
                } else if !model.pendingFiles.isEmpty {
                    Button("Upload ^[\(model.pendingFiles.count) File](inflect: true)") {
                        model.uploadPendingFiles()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(model.path == "/" ? NSLocalizedString("File System", comment: "") : (model.path as NSString).lastPathComponent)
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

#Preview {
    NavigationStack {
        FileSystemView()
    }
}
