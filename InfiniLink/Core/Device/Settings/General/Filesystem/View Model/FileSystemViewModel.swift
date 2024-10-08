//
//  FileSystemViewModel.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import Foundation
import UIKit

class FileSystemViewModel: ObservableObject {
    static let shared = FileSystemViewModel()
    
    @Published var directory = "/"
    @Published var commandHistory: [String] = []
    
    @Published var loadingFs = false
    @Published var fileUploading = false
    @Published var fileConverting = false
    @Published var fileSelected = false
    @Published var showSettingsView = false
    @Published var showUploadSheet = false
    @Published var showNewFolderView = false
    
    @Published var files = [File]()
    
    @Published var fileSize = 0
    
    func uploadFiles() {
        let bleFSHandler = BLEFSHandler.shared
        
        DispatchQueue.global(qos: .default).async {
            for file in self.files {
                let lowercaseFilename = file.filename.lowercased()
                
                guard let fileDataPath = file.url else {
                    continue
                }
                
                do {
                    if lowercaseFilename.hasSuffix(".png") ||
                        lowercaseFilename.hasSuffix(".jpg") ||
                        lowercaseFilename.hasSuffix(".jpeg") ||
                        lowercaseFilename.hasSuffix(".gif") || lowercaseFilename.hasSuffix(".bmp") ||
                        lowercaseFilename.hasSuffix(".tiff") ||
                        lowercaseFilename.hasSuffix(".webp") ||
                        lowercaseFilename.hasSuffix(".heif") ||
                        lowercaseFilename.hasSuffix(".heic") {
                        
                        guard let img = UIImage(contentsOfFile: fileDataPath.path),
                              let cgImage = img.cgImage else {
                            continue
                        }
                        
                        self.fileSize = 0
                        
                        self.fileConverting = true
                        let convertedImage = lvImageConvert(img: cgImage)
                        self.fileConverting = false
                        
                        let fileNameWithoutExtension = (file.filename as NSString).deletingPathExtension
                        if let convertedImage = convertedImage {
                            self.fileSize = convertedImage.count
                            self.fileUploading = true
                            var _ = bleFSHandler.writeFile(data: convertedImage, path: self.directory + "/" + String(fileNameWithoutExtension.prefix(30).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)) + ".bin", offset: 0)
                        }
                    } else {
                        self.fileSize = 0
                        let fileData = try Data(contentsOf: fileDataPath)
                        self.fileSize = fileData.count
                        
                        self.fileUploading = true
                        var _ = bleFSHandler.writeFile(data: fileData, path: self.directory + "/" + file.filename, offset: 0)
                    }
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
            self.fileUploading = false
            
            self.fileSelected = false
            self.files = []
            
            self.lsDir(dir: self.directory)
        }
    }
    
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
                self.clearList()
                
                self.directory = newDir
                self.lsDir(dir: dir)
            } else {
                print("ERROR: dir '\(newDir)' is not valid.")
            }
            self.loadingFs = false
        }
    }
    
    func lsDir(dir: String) {
        loadingFs = true
        
        DispatchQueue.global(qos: .default).async {
            let dirLS = BLEFSHandler.shared.listDir(path: self.directory)
            if dirLS.valid {
                self.clearList()
                
                for dir in dirLS.ls {
                    self.commandHistory.append("\(dir.pathNames)")
                }
            } else {
                print("ERROR: dir '\(self.directory)' is not valid.")
            }
            self.loadingFs = false
        }
    }
    
    func createDir(name: String) {
        loadingFs = true
        
        DispatchQueue.global(qos: .default).async {
            let mkDir = BLEFSHandler.shared.makeDir(path: self.directory + "/" + name)
            if !mkDir {
                print("ERROR: failed to create folder with name: '\(name)'.")
            }
            self.lsDir(dir: self.directory)
            self.loadingFs = false
        }
    }
    
    func deleteFile(fileName: String) {
        let path: String = {
            if self.directory.isEmpty {
                return fileName
            } else {
                return self.directory + "/" + fileName
            }
        }()
        
        loadingFs = true
        DispatchQueue.global(qos: .default).async {
            let rmDir = BLEFSHandler.shared.deleteFile(path: path)
            if !rmDir {
                print("ERROR: failed to remove file with path '\(path)'.")
            }
            self.loadingFs = false
            self.lsDir(dir: self.removeLastPathComponent(path))
        }
    }
}
