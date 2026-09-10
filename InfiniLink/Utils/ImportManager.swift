//
//  ImportManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/10/26.
//

import Foundation
import SwiftUI

// Handles zip files handed to InfiniLink from the system share sheet ("Copy to InfiniLink")
// or the Files app. The user is asked whether the zip is firmware or external resources,
// then it's fed into the same local-file update path as "Other Versions".
class ImportManager: ObservableObject {
    static let shared = ImportManager()

    struct PendingZip: Identifiable {
        let id = UUID()
        let url: URL

        var filename: String { url.lastPathComponent }
    }

    // Non-nil while we're asking the user what the shared zip is for
    @Published var pendingZip: PendingZip?
    // Drives the Software Update sheet once the user has made a choice
    @Published var showUpdateFlow = false

    private let downloadManager = DownloadManager.shared
    private let dfuUpdater = DFUUpdater.shared

    // Called from `.onOpenURL` when a file is opened into the app
    func handleIncomingFile(_ url: URL) {
        guard url.pathExtension.lowercased() == "zip" else {
            log("Ignoring shared file that isn't a zip: \(url.lastPathComponent)", caller: "ImportManager")
            return
        }
        guard !downloadManager.updateStarted else {
            log("Ignoring shared zip because an update is already in progress", caller: "ImportManager")
            return
        }

        let didAccessScope = url.startAccessingSecurityScopedResource()
        defer { if didAccessScope { url.stopAccessingSecurityScopedResource() } }

        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

            // Clear out any zip left behind by a previous, abandoned import
            let stale = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix("shared-") }
            for file in stale {
                try? FileManager.default.removeItem(at: file)
            }

            let destination = documentsURL.appendingPathComponent("shared-\(url.lastPathComponent)")
            try FileManager.default.copyItem(at: url, to: destination)

            // iOS drops share-sheet copies in Documents/Inbox; we've made our own copy now
            if url.pathComponents.contains("Inbox") {
                try? FileManager.default.removeItem(at: url)
            }

            DispatchQueue.main.async {
                self.pendingZip = PendingZip(url: destination)
            }
        } catch {
            log("Couldn't import shared zip: \(error.localizedDescription)", caller: "ImportManager")
        }
    }

    func chooseFirmware(_ zip: PendingZip) {
        dfuUpdater.local = true
        dfuUpdater.firmwareSelected = true
        dfuUpdater.resourceFilename = zip.filename
        dfuUpdater.firmwareFilename = zip.filename
        dfuUpdater.firmwareURL = zip.url
        dfuUpdater.resourceURL = nil
        downloadManager.updateBody = NSLocalizedString("This is a local firmware file and cannot be verified. Proceed at your own risk.", comment: "")
        downloadManager.updateSize = dfuUpdater.fileSize(from: zip.url)
        downloadManager.externalResources = false
        downloadManager.updateAvailable = true

        pendingZip = nil
        showUpdateFlow = true
    }

    func chooseExternalResources(_ zip: PendingZip) {
        dfuUpdater.local = true
        dfuUpdater.firmwareSelected = true
        dfuUpdater.firmwareURL = nil
        dfuUpdater.resourceFilename = zip.filename
        dfuUpdater.resourceURL = zip.url
        downloadManager.updateBody = NSLocalizedString("External resources are fonts and images not included in the firmware required to use some apps and watch faces.", comment: "")
        downloadManager.updateSize = dfuUpdater.fileSize(from: zip.url)
        downloadManager.externalResources = true

        pendingZip = nil
        showUpdateFlow = true
    }

    func cancelImport() {
        if let zip = pendingZip {
            try? FileManager.default.removeItem(at: zip.url)
        }
        pendingZip = nil
    }
}
