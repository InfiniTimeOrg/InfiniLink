//
//  FilesystemView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import SwiftUI

struct File: Identifiable {
    let id = UUID()
    var url: URL?
    var filename: String
}

struct FileSystemToolbar: ViewModifier {
    @ObservedObject var fileSystemViewModel = FileSystemViewModel.shared
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            fileSystemViewModel.showNewFolderView = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Button {
                            fileSystemViewModel.showUploadSheet = true
                        } label: {
                            Label("Upload Files", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!BLEManager.shared.hasLoadedCharacteristics || fileSystemViewModel.loadingFs || fileSystemViewModel.fileUploading)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if fileSystemViewModel.fileSelected {
                        if fileSystemViewModel.fileUploading {
                            ProgressView({
                                if fileSystemViewModel.fileConverting {
                                    return NSLocalizedString("Converting...", comment: "")
                                } else {
                                    if fileSystemViewModel.fileSize != 0 {
                                        let progressPercentage = Int(Double(BLEFSHandler.shared.progress) / Double(fileSystemViewModel.fileSize) * 100)
                                        
                                        return NSLocalizedString("Uploading...\(progressPercentage)%", comment: "")
                                    } else {
                                        return NSLocalizedString("Uploading...", comment: "")
                                    }
                                }
                            }())
                        } else {
                            Button {
                                fileSystemViewModel.uploadFiles()
                            } label: {
                                let count = fileSystemViewModel.files.count
                                
                                Text("Upload \(count) File\(count == 1 ? "" : "s")")
                                    .padding(12)
                                    .padding(.horizontal, 4)
                                    .foregroundStyle(.white)
                                    .background(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                            .padding(.top)
                        }
                    }
                }
            }
    }
}

struct FileSystemFolderDetailView: View {
    @ObservedObject var fileSystemViewModel = FileSystemViewModel.shared
    
    var body: some View {
        List {
            ForEach(fileSystemViewModel.commandHistory, id: \.self) { listItem in
                let isFile = listItem.contains(".")
                
                if listItem != "." && listItem != ".." {
                    if isFile && listItem == "settings.dat" {
                        Button {
                            fileSystemViewModel.showSettingsView = true
                        } label: {
                            Text(listItem)
                        }
                        .sheet(isPresented: $fileSystemViewModel.showSettingsView) {
//                             WatchSettingsView()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                fileSystemViewModel.deleteFile(fileName: listItem)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .disabled(fileSystemViewModel.fileUploading)
                    } else {
                        NavigationLink {
                            FileSystemFolderDetailView()
                                .navigationTitle(listItem)
                                .navigationBarBackButtonHidden(fileSystemViewModel.fileUploading)
                                .modifier(FileSystemToolbar())
                                .onAppear {
                                    fileSystemViewModel.loadingFs = true
                                    fileSystemViewModel.cdAndLs(dir: listItem)
                                }
                        } label: {
                            Text(listItem)
                        }
                        .disabled(fileSystemViewModel.fileUploading)
                    }
                }
            }
        }
    }
}

struct FileSystemView: View {
    @Environment(\.presentationMode) var presMode
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var bleFSHandler = BLEFSHandler.shared
    @ObservedObject var fileSystemViewModel = FileSystemViewModel.shared
    
    @State var newFolderName = ""
    
    @FocusState var isNewFolderFocused: Bool
    
    var body: some View {
            Group {
                if fileSystemViewModel.loadingFs || !BLEManager.shared.hasLoadedCharacteristics {
                    List {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    FileSystemFolderDetailView()
                }
            }
            .navigationTitle("File System")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(fileSystemViewModel.fileUploading)
            .sheet(isPresented: $fileSystemViewModel.showNewFolderView) {
                newFolder
            }
            .modifier(FileSystemToolbar())
            .fileImporter(isPresented: $fileSystemViewModel.showUploadSheet, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
                do {
                    let fileURLs = try result.get()
                    
                    self.fileSystemViewModel.files.removeAll()
                    for fileURL in fileURLs {
                        guard fileURL.startAccessingSecurityScopedResource() else { continue }
                        
                        self.fileSystemViewModel.fileSelected = true
                        self.fileSystemViewModel.files.append(File(url: fileURL, filename: fileURL.lastPathComponent))
                        
                        // Don't call .stopAccessingSecurityScopedResource() as the upload button won't work due to lack of necessary permissions
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            .onAppear {
//                 fileSystemViewModel.lsDir(dir: "/")
            }
    }
    
    var newFolder: some View {
        NavigationView {
            Form {
                TextField("Title", text: $newFolderName)
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        fileSystemViewModel.showNewFolderView = false
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        fileSystemViewModel.createDir(name: newFolderName)
                        fileSystemViewModel.showNewFolderView = false
                    } label: {
                        Text("Create")
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isNewFolderFocused = true
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    NavigationView {
        FileSystemView()
    }
}
