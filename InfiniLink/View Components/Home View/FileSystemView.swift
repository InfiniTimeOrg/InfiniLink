//
//  FileSystemView.swift
//  InfiniLink
//
//  Created by Liam Willey on 2/9/24.
//

import SwiftUI

struct File: Identifiable {
    let id = UUID()
    var url: URL?
    var filename: String
}

struct FileSystemView: View {
    @Environment(\.presentationMode) var presMode
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var bleFSHandler = BLEFSHandler.shared
    
    @State var loadingFs = false
    @State var showUploadSheet = false
    @State var fileSelected = false
    @State var showNewFolderView = false
    @State var fileUploading = false
    
    @State var files: [File] = []
    @State var newFolderName = ""
    @State var directory = "/"
    
    @State var commandHistory: [String] = []
    
    func clearList() {
        commandHistory = []
    }
    
    func getDir(input: String) -> String {
        return input.first == "/" ? input : directory.last == "/" ? "\(directory)\(input)" : "\(directory)/\(input)"
    }
    
    func removeLastPathComponent(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let updatedURL = url.deletingLastPathComponent()
        return updatedURL.path
    }
    
    func cdAndLs(dir: String) {
        loadingFs = true
        
        let newDir = getDir(input: dir)
        DispatchQueue.global(qos: .default).async {
            let dirLS = BLEFSHandler.shared.listDir(path: newDir)
            if dirLS.valid {
                clearList()
                
                directory = newDir
                lsDir(dir: dir)
            } else {
                print("ERROR: dir '\(newDir)' is not valid.")
            }
            loadingFs = false
        }
    }
    
    func lsDir(dir: String) {
        loadingFs = true
        
        DispatchQueue.global(qos: .default).async {
            let dirLS = BLEFSHandler.shared.listDir(path: directory)
            if dirLS.valid {
                clearList()
                
                for dir in dirLS.ls {
                    commandHistory.append("\(dir.pathNames)")
                }
            } else {
                print("ERROR: dir '\(directory)' is not valid.")
            }
            loadingFs = false
        }
    }
    
    func createDir(name: String) {
        loadingFs = true
        
        DispatchQueue.global(qos: .default).async {
            let mkDir = BLEFSHandler.shared.makeDir(path: directory + "/" + name)
            if !mkDir {
                print("ERROR: failed to create folder with name: '\(name)'.")
            }
            lsDir(dir: directory)
            loadingFs = false
        }
    }
    
    func deleteFile(path: String) {
        loadingFs = true
        DispatchQueue.global(qos: .default).async {
            let rmDir = BLEFSHandler.shared.deleteFile(path: path)
            if !rmDir {
                print("ERROR: failed to remove file with path '\(path)'.")
            }
            loadingFs = false
            lsDir(dir: removeLastPathComponent(path))
        }
    }
    
    var body: some View {
        if UptimeManager.shared.connectTime != nil {
            content
        } else {
            DFUWithoutBLE(title: NSLocalizedString("pinetime_not_available", comment: ""), subtitle: NSLocalizedString("please_check_your_connection_and_try_again", comment: ""))
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .disabled(fileUploading)
                .opacity(fileUploading ? 0.5 : 1.0)
                Text(NSLocalizedString("file_system", comment: ""))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                Menu {
                    Button {
                        showNewFolderView = true
                    } label: {
                        Label(NSLocalizedString("new_folder", comment: "New Folder"), systemImage: "folder.badge.plus")
                    }
                    Button {
                        showUploadSheet = true
                    } label: {
                        Label(NSLocalizedString("upload_files", comment: "Upload File(s)"), systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(fileUploading)
                .opacity(fileUploading ? 0.5 : 1.0)
                .fileImporter(isPresented: $showUploadSheet, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
                    do {
                        let fileURLs = try result.get()
                        
                        for fileURL in fileURLs {
                            // Add more supported file types?
//                            if ["bin", "txt"].contains(fileURL.pathExtension.lowercased()) {
                                guard fileURL.startAccessingSecurityScopedResource() else { continue }
                                
                                self.fileSelected = true
                                self.files.append(File(url: fileURL, filename: fileURL.lastPathComponent))
                                
                                // Don't stop accessing the security-scoped resource because then the upload button won't work due to lack of necessary permissions
                                // fileURL.stopAccessingSecurityScopedResource()
//                            }
                        }
                    } catch {
                        DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            ScrollView {
                VStack {
                    if loadingFs {
                        ProgressView()
                    } else {
                        if directory != "/" {
                            Button {
                                let currentDir = directory
                                
                                directory = removeLastPathComponent(currentDir)
                                lsDir(dir: directory)
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text(NSLocalizedString("back", comment: "Back"))
                                }
                                .modifier(RowModifier(style: .capsule))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        ForEach(commandHistory, id: \.self) { listItem in
                            let isFile = listItem.contains(".")
                            
                            if listItem != "." && listItem != ".." {
                                Button {
                                    if isFile {
                                        if listItem == "settings.dat" {
                                            bleFSHandler.readSettings { settings in
                                                print(settings)
                                            }
                                        } else {
                                            
                                        }
                                    } else {
                                        loadingFs = true
                                        cdAndLs(dir: listItem)
                                    }
                                } label: {
                                    HStack {
                                        Text(listItem)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Spacer()
                                        if !isFile {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .modifier(RowModifier(style: .capsule))
                                }
                                .contextMenu {
                                    Button {
                                        deleteFile(path: directory + "/" + listItem)
                                    } label: {
                                        Label(NSLocalizedString("delete", comment: "Delete"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            if fileSelected {
                Divider()
                if fileUploading {
                    ProgressView()
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        if files.count < 2 {
                            Text(files.first?.filename ?? NSLocalizedString("unknown", comment: "Unknown"))
                                .padding(12)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(files, id: \.id) { file in
                                        Text(file.filename)
                                            .padding(12)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding()
                            }
                            .padding(-16)
                        }
                        Button {
                            self.fileUploading = true
                            
                            DispatchQueue.global(qos: .default).async {
                                do {
                                    for file in files {
                                        let fileDataPath = file.url
                                        let fileData = try Data(contentsOf: fileDataPath!)
                                        let _ = bleFSHandler.writeFile(data: fileData, path: directory + "/" + file.filename, offset: 0)
                                    }
                                    
                                    self.fileUploading = false
                                    
                                    self.fileSelected = false
                                    self.files = []
                                    
                                    lsDir(dir: directory)
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        } label: {
                            Text(NSLocalizedString("upload_selected_files", comment: "Upload Selected File(s)"))
                                .padding(12)
                                .padding(.horizontal, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showNewFolderView) {
            VStack {
                HStack {
                    Text(NSLocalizedString("new_folder", comment: ""))
                        .font(.title.bold())
                    Spacer()
                    Button {
                        showNewFolderView = false
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .padding(14)
                            .font(.body.weight(.semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                Spacer()
                TextField(NSLocalizedString("title", comment: "Title"), text: $newFolderName)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
                Button {
                    createDir(name: newFolderName)
                    showNewFolderView = false
                } label: {
                    Text(NSLocalizedString("create_folder", comment: "Create Folder"))
                        .frame(maxWidth: .infinity)
                        .font(.body.weight(.semibold))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .onAppear {
            loadingFs = true
            lsDir(dir: "/")
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
}

#Preview {
    FileSystemView()
}
