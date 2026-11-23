//
//  FileSystemViewModel.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import Foundation

class FileSystemViewModel: ObservableObject {
    let path: String
    
    @Published var entries: [BLEFSHandler.Dir] = []
    @Published var isLoading = false
    @Published var pendingFiles: [URL] = []
    @Published var pendingRestore: WatchBackup.Contents?
    @Published var showOpenBackupError = false
    
    private let bleFs = BLEFSHandler.shared
    private let transfer = FileTransferManager.shared
    
    init(path: String) {
        self.path = path
    }
    
    func path(for name: String) -> String {
        (path == "/" ? "" : path) + "/" + name
    }
    
    func load() {
        if let cached = bleFs.cachedListing(path: path) {
            entries = cached
            isLoading = false
            return
        }
        
        isLoading = true
        fetch { self.isLoading = false }
    }
    
    @MainActor
    func refresh() async { // Don't use the cached list for pull to refresh
        await withCheckedContinuation { continuation in
            fetch { continuation.resume() }
        }
    }
    
    private func fetch(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let listing = self.bleFs.listDir(path: self.path)?.filter { $0.pathNames != "." && $0.pathNames != ".." }
            if let listing {
                self.bleFs.cacheListing(listing, path: self.path)
            }
            
            DispatchQueue.main.async {
                self.entries = listing ?? []
                completion()
            }
        }
    }
    
    func createFolder(named name: String) {
        perform { _ = self.bleFs.makeDir(path: self.path(for: name)) }
    }
    
    func delete(_ entry: BLEFSHandler.Dir) {
        perform { _ = self.bleFs.deleteFile(path: self.path(for: entry.pathNames)) }
    }
    
    func uploadPendingFiles() {
        transfer.upload(pendingFiles, to: path)
        pendingFiles = []
    }
    
    func openBackup(_ url: URL) {
        pendingRestore = WatchBackup().open(url)
        showOpenBackupError = pendingRestore == nil
    }
    
    func restore(_ contents: WatchBackup.Contents) {
        transfer.restore(contents)
    }
    
    // Runs a change on the watch, then reloads the list
    private func perform(_ change: @escaping () -> Void) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            change()
            DispatchQueue.main.async { self.load() }
        }
    }
}
