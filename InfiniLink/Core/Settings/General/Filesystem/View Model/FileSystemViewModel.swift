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
    @Published var showUploadSheet = false
    @Published var fileUploading = false
    @Published var fileConverting = false
    @Published var showNewFolderView = false
    @Published var fileSelected = false
    
    @Published var fileSize = 0
    
    @Published var files = [FSFile]()
    
    func clearList() {
        DispatchQueue.main.async {
            self.commandHistory = []
        }
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
        
        DispatchQueue.main.async {
            let newDir = self.getDir(input: dir)
            
            self.clearList()
            self.directory = newDir
            self.lsDir(dir: dir)
            self.loadingFs = false
        }
    }
    
    func lsDir(dir: String) {
        DispatchQueue.main.async {
            self.loadingFs = true
        }
        
        DispatchQueue.global(qos: .default).async {
            let dirLS = BLEFSHandler.shared.listDir(path: self.directory)
            if dirLS.valid {
                self.clearList()
                
                DispatchQueue.main.async {
                    self.commandHistory.append(contentsOf: dirLS.ls.compactMap({ $0.pathNames }))
                    self.loadingFs = false
                }
            } else {
                print("ERROR: dir '\(self.directory)' is not valid.")
            }
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
        loadingFs = true
        
        DispatchQueue.global(qos: .default).async {
            let path = self.getDir(input: fileName)
            let rmDir = BLEFSHandler.shared.deleteFile(path: path)
            
            if !rmDir {
                log("Failed to remove file with path: \(path)", caller: "FileSystemViewModel", target: .ble)
            }
            
            DispatchQueue.main.async {
                self.loadingFs = false
            }
            self.lsDir(dir: self.removeLastPathComponent(path))
        }
    }
}
