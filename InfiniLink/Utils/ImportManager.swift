//
//  ImportManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/10/26.
//

import Foundation
import SwiftUI

class ImportManager: ObservableObject {
    static let shared = ImportManager()

    @Published var importError: String?
    @Published var showUpdateFlow = false

    private let downloadManager = DownloadManager.shared

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

            if url.pathComponents.contains("Inbox") {
                try? FileManager.default.removeItem(at: url)
            }

            DispatchQueue.main.async {
                if self.downloadManager.selectLocalFile(destination) {
                    self.showUpdateFlow = true
                } else {
                    try? FileManager.default.removeItem(at: destination)
                    self.importError = String(localized: "\"\(url.lastPathComponent)\" isn't a firmware update or external resources.")
                }
            }
        } catch {
            log("Couldn't import shared zip: \(error.localizedDescription)", caller: "ImportManager")
        }
    }
}
