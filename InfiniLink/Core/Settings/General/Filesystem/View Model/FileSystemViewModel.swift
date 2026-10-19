//
//  FileSystemViewModel.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class FileSystemViewModel: ObservableObject {
    let path: String
    
    @Published var entries: [BLEFSHandler.Dir] = []
    @Published var isLoading = false
    @Published var pendingFiles: [URL] = []
    @Published var isUploading = false
    @Published var uploadSize = 0
    
    private let bleFs = BLEFSHandler.shared
    
    init(path: String) {
        self.path = path
    }
    
    func path(for name: String) -> String {
        (path == "/" ? "" : path) + "/" + name
    }
    
    func load() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let entries = self.bleFs.listDir(path: self.path)
            
            DispatchQueue.main.async {
                self.entries = (entries ?? []).filter { $0.pathNames != "." && $0.pathNames != ".." }
                self.isLoading = false
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
        let files = pendingFiles
        isUploading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            for url in files {
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
                
                guard let upload = self.uploadData(for: url) else {
                    log("Couldn't read \(url.lastPathComponent) for upload", caller: "FileSystemViewModel", target: .ble)
                    continue
                }
                
                DispatchQueue.main.async { self.uploadSize = upload.data.count }
                _ = self.bleFs.writeFile(data: upload.data, path: self.path(for: upload.name))
            }
            
            DispatchQueue.main.async {
                self.isUploading = false
                self.pendingFiles = []
                self.load()
            }
        }
    }
    
    // Runs a change on the watch, then reloads the list
    private func perform(_ change: @escaping () -> Void) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            change()
            DispatchQueue.main.async { self.load() }
        }
    }
    
    // Images are converted to LVGL's format so the watch can show them
    private func uploadData(for url: URL) -> (data: Data, name: String)? {
        guard UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true else {
            return (try? Data(contentsOf: url)).map { ($0, url.lastPathComponent) }
        }
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage, let data = lvImageConvert(img: image) else { return nil }
        
        let name = url.deletingPathExtension().lastPathComponent.prefix(26).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
        return (data, name + ".bin")
    }
}
