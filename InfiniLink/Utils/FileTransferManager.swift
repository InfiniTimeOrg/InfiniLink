//
//  FileTransferManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 11/23/26.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class FileTransferManager: ObservableObject {
    static let shared = FileTransferManager()

    enum Task {
        case uploading
        case backingUp
        case restoring
    }

    @Published private(set) var task: Task?
    @Published private(set) var completedFiles = 0
    @Published private(set) var fileCount = 0
    @Published private(set) var fileSize = 0
    @Published var backupURL: URL?
    @Published var restoreResult: WatchBackup.RestoreResult?
    @Published var showBackupError = false

    private let bleFs = BLEFSHandler.shared
    private let backup = WatchBackup()

    var statusText: String {
        switch task {
        case .uploading:
            return NSLocalizedString("Uploading", comment: "")
        case .backingUp:
            return NSLocalizedString("Backing Up", comment: "")
        case .restoring:
            return NSLocalizedString("Restoring", comment: "")
        case nil:
            return ""
        }
    }

    func fractionComplete(bytesWritten: Int) -> Double {
        guard fileCount > 0 else { return 0 }

        let current = fileSize > 0 ? min(Double(bytesWritten) / Double(fileSize), 1) : 0
        return (Double(completedFiles) + current) / Double(fileCount)
    }

    func upload(_ files: [URL], to directory: String) {
        start(.uploading)
        fileCount = files.count

        DispatchQueue.global(qos: .userInitiated).async {
            for (index, url) in files.enumerated() {
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }

                guard let upload = self.uploadData(for: url) else {
                    log("Couldn't read \(url.lastPathComponent) for upload", caller: "FileTransferManager", target: .ble)
                    continue
                }

                DispatchQueue.main.async { self.update(index, files.count, upload.data.count) }
                _ = self.bleFs.writeFile(data: upload.data, path: (directory == "/" ? "" : directory) + "/" + upload.name)
            }

            DispatchQueue.main.async { self.task = nil }
        }
    }

    func backUp() {
        start(.backingUp)

        backup.create(progress: update) { url in
            self.task = nil
            self.backupURL = url
            self.showBackupError = url == nil
        }
    }

    func restore(_ contents: WatchBackup.Contents) {
        start(.restoring)

        backup.restore(contents, progress: update) { result in
            self.task = nil
            self.restoreResult = result
        }
    }

    private func start(_ task: Task) {
        self.task = task
        completedFiles = 0
        fileCount = 0
        fileSize = 0
    }

    private func update(_ completed: Int, _ total: Int, _ size: Int) {
        completedFiles = completed
        fileCount = total
        fileSize = size
    }

    private func uploadData(for url: URL) -> (data: Data, name: String)? {
        guard UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true else {
            return (try? Data(contentsOf: url)).map { ($0, url.lastPathComponent) }
        }
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage, let data = lvImageConvert(img: image) else { return nil }

        let name = url.deletingPathExtension().lastPathComponent.prefix(26).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
        return (data, name + ".bin")
    }
}
